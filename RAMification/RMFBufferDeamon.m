//
//  RMFBufferDeamon.m
//  RAMification
//
//  Created by michael starke on 06.09.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFBufferDeamon.h"

#import "RMFFavouritesManager.h"
#import "RMFMountWatcher.h"
#import "RMFRamdisk.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"

@interface RMFBufferDeamon () {
  FSEventStreamRef _eventStream;
}
@property (retain) NSMutableSet *watchedURLs;
@property (assign) BOOL isObservingNotifications;
@property (retain) NSDate *lastUpdate;
@property (assign) FSEventStreamEventId lastEventId;
@property (nonatomic, setter = setBufferEnabled:) BOOL bufferEnabled;

- (void)eventsAtPath:(NSArray *)paths flags:(const FSEventStreamEventFlags[])flags;
- (void)enable:(BOOL)enable;
- (void)didUnmountRamdisk:(NSNotification *)notification;
- (void)didMountRamdisk:(NSNotification *)notification;
- (void)didRenameRamdisk:(NSNotification *)notification;
- (void)updateCallback;
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk;
- (void)addWatchedURL:(NSURL *)url;
- (void)clearWatchedURLs;
- (void)removeWatchedURL:(NSURL *)url;
- (void)shouldBuffer:(BOOL)disable file:(NSString*)file;
@end


static void fileSystemEventCallback(ConstFSEventStreamRef streamRef
                                    , void *userData
                                    , size_t numEvents
                                    , void *eventPaths
                                    , const FSEventStreamEventFlags eventFlags[]
                                    , const FSEventStreamEventId eventIds[]) {
  RMFBufferDeamon *bufferDaemon = (RMFBufferDeamon *)userData;
  [bufferDaemon eventsAtPath:(NSArray *)eventPaths flags:eventFlags];
}

@implementation RMFBufferDeamon

- (id)init {
  self = [super init];
  if (self) {
    _watchedURLs = [[NSMutableSet alloc] init];
    _eventStream = NULL;
    _lastUpdate = [[NSDate alloc] init];
    _isObservingNotifications = NO;
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSString *keyPath = [NSString stringWithFormat:@"values.%@", kRMFSettingsKeyDisableUnifiedBuffer];
    [self bind:@"bufferEnabled" toObject:defaultsController withKeyPath:keyPath options:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

-(void)dealloc {
  if(YES == _isObservingNotifications ) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
  [super dealloc];
}

- (void)setBufferEnabled:(BOOL)bufferEnabled {
  NSLog(@"%@: Called setBufferEnabled", self);
  if(bufferEnabled != _bufferEnabled) {
    _bufferEnabled = bufferEnabled;
    [self enable:bufferEnabled];
  }
}

- (void)enable:(BOOL)enable {
  
  NSArray *mountedRamdisks = [[RMFFavouritesManager sharedManager] mountedFavourites];
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

  if(enable) {
    for(RMFRamdisk *ramdisk in mountedRamdisks) {
      [self setShouldBuffer:enable forRamdisk:ramdisk];
    }
    // Register for notifications
    if( NO == _isObservingNotifications) {
      [defaultCenter addObserver:self selector:@selector(didMountRamdisk:) name:RMFDidMountRamdiskNotification object:nil];
      [defaultCenter addObserver:self selector:@selector(didUnmountRamdisk:) name:RMFDidUnmountRamdiskNotification object:nil];
      [defaultCenter addObserver:self selector:@selector(didRenameRamdisk:) name:RMFDidRenameRamdiskNotification object:nil];
      self.isObservingNotifications = YES;
    }
  }
  else {
    // Unregister the notifications
    if( YES == _isObservingNotifications) {
      [defaultCenter removeObserver:self];
      self.isObservingNotifications = NO;
    }

    [self clearWatchedURLs];
    for(RMFRamdisk *ramdisk in mountedRamdisks) {
      // enable buffer for all files on ramdisk ... potentially dangerous?
    }
  }
}

# pragma mark callback handling
- (void)eventsAtPath:(NSArray *)paths flags:(const FSEventStreamEventFlags [])flags {
  /*
   We receive events for paths that we watch
   
   Handle root changes (= renaming)
   Handle unmountings (> remove from watchlist)
   Update buffer on new files
   
   Ignore Mount, Removal (nothing to do there)
   */
  for(NSString *path in paths) {
    NSUInteger index = [paths indexOfObject:path];
    FSEventStreamEventFlags flag = flags[index];
    NSLog(@"FS Event for %@ flag: %d", path, flag);
    if(flag & kFSEventStreamEventFlagItemCreated) {
      NSLog(@"Created");
      // need to find out WHAT was created!
    }
    if(flag & kFSEventStreamEventFlagItemXattrMod) {
      NSLog(@"X-Attributes Modified");
    }
    if(flag & kFSEventStreamEventFlagItemRenamed) {
      NSLog(@"Renamed");
    }
  }
}

- (void)updateCallback {
  
  // Unshedule the Eventstream callback but remmber the last eventID
  if( _eventStream != NULL ) {
    FSEventStreamStop(_eventStream);
    FSEventStreamInvalidate(_eventStream);
    self.lastEventId = FSEventStreamGetLatestEventId(_eventStream);
    FSEventStreamRelease(_eventStream);
    _eventStream = NULL;
  }
  else {
    self.lastEventId = FSEventsGetCurrentEventId();
  }
  
  // We got no paths to watch, leave
  if([self.watchedURLs count] == 0) {
    return; // nothing to watch
  }
  
  // We got some paths to watch so generate a new callback
  FSEventStreamContext context = {0, (void *)self, NULL, NULL, NULL};
  const NSTimeInterval latency = 1.0;
  // Watch for File events (Create, Modify, Remove,) and use CF Storage types on callback
  const FSEventStreamCreateFlags flags = (kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes);
  
  NSMutableSet *paths = [[[NSMutableSet alloc] initWithCapacity:[_watchedURLs count]] autorelease];
  for(NSURL *url in _watchedURLs) {
    [paths addObject:[url path]];
  }
  _eventStream = FSEventStreamCreate(NULL,
                                     &fileSystemEventCallback,
                                     &context,
                                     (CFArrayRef)[paths allObjects],
                                     _lastEventId,
                                     (CFTimeInterval)latency,
                                     flags);
  
  FSEventStreamScheduleWithRunLoop(_eventStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
  FSEventStreamStart(_eventStream);
}

# pragma mark Notifictaions
- (void)didMountRamdisk:(NSNotification *)notification {
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:kRMFRamdiskKey];
  if(ramdisk != nil) {
    [self addWatchedURL:ramdisk.volumeURL];
  }
}

- (void)didUnmountRamdisk:(NSNotification *)notification {
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:kRMFRamdiskKey];
  if(ramdisk != nil) {
    [self removeWatchedURL:ramdisk.volumeURL];
  }
}

- (void)didRenameRamdisk:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSURL *oldURL = [userInfo objectForKey:kRMFRamdiskVolumeURLBeforeRenameKey];
  RMFRamdisk *ramdisk = [userInfo objectForKey:kRMFRamdiskKey];
  
  if(ramdisk != nil) {
    [self removeWatchedURL:oldURL];
    [self addWatchedURL:ramdisk.volumeURL];
  }
}

#pragma mark Buffer handling
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk {
  
  if( shouldBuffer ) {
    [self addWatchedURL:ramdisk.volumeURL];
  }
  else {
    [self removeWatchedURL:ramdisk.volumeURL];
  }
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *volumePath = [ramdisk.volumeURL path];
  NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:volumePath];
  NSString *file;
  while( file = [dirEnumerator nextObject] ) {
    [self shouldBuffer:(!shouldBuffer) file:file];
  }
}

#pragma mark path updates

- (void)addWatchedURL:(NSURL *)url {
  // Add the volume path to the watched paths
  NSError *error = nil;
  NSDictionary *resourceValues = [url resourceValuesForKeys:@[NSURLIsVolumeKey, ] error:&error];
  if(error != nil) {
    NSLog(@"%@: An Error occured while trying to wath URL %@ for changes. %@", [self class], url, [error localizedDescription]);
    return; // error while reading
  }
  BOOL isVolume = [[resourceValues objectForKey:NSURLIsVolumeKey] boolValue];
  if(NO == isVolume) {
    NSLog(@"%@: URL %@ does not point to a Volume. Ignoring", [self class], url);
    return; // URL does not point to a Volume
  }
  // Insert path into watched paths
  if([self.watchedURLs containsObject:url]) {
    return; // path is already in watchlist
  }
  [self.watchedURLs addObject:url];
  [self updateCallback];
}

- (void)clearWatchedURLs {
  [self.watchedURLs removeAllObjects];
  [self updateCallback];
}

- (void)removeWatchedURL:(NSURL *)url {
  if([self.watchedURLs containsObject:url]) {
    [self.watchedURLs removeObject:url];
    [self updateCallback];
  }
}

- (void)shouldBuffer:(BOOL)shouldBuffer file:(NSString *)file {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(NO == [fileManager fileExistsAtPath:file]) {
    return; // No valid file found
  }
  NSString *actionString = (shouldBuffer ? @"enable" : @"disable");
  const int fileDesciptor= open([file UTF8String], O_RDONLY);
  if(fileDesciptor >= 0) {
    if(shouldBuffer){
      //fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 0); // Turn UBC on
      
    }
    else {
      //fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 1); // Turn UBC off
    }
    close(fileDesciptor);
    NSLog(@"%@: Did %@ cache for file %@ !", self, actionString, file );
  }
  else {
    NSLog(@"%@: Could not %@ cache for file %@ becaus the File could not be found!", self, actionString, file );
  }
}
@end

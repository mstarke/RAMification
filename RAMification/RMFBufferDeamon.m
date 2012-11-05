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
@property (retain) NSMutableSet *watchedDisks;
@property (assign) BOOL isObservingNotifications;
@property (retain) NSDate *lastUpdate;
@property (assign) FSEventStreamEventId lastEventId;
@property (nonatomic, setter = setBufferEnabled:) BOOL bufferEnabled;

- (void)update:(const FSEventStreamEventFlags[])flags;
- (void)enable:(BOOL)enable;
- (void)didUnmountRamdisk:(NSNotification *)notification;
- (void)didMountRamdisk:(NSNotification *)notification;
- (void)didRenameRamdisk:(NSNotification *)notification;
- (void)updateCallback;
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk;
- (void)addWatchedPath:(NSString *)path;
- (void)clearWatchedPaths;
- (void)removeWatchedPath:(NSString *)path;
- (void)shouldBuffer:(BOOL)disable file:(NSString*)file;
@end


static void fileSystemEventCallback(ConstFSEventStreamRef streamRef
                                    , void *userData
                                    , size_t numEvents
                                    , void *eventPaths
                                    , const FSEventStreamEventFlags eventFlags[]
                                    , const FSEventStreamEventId eventIds[]) {
  RMFBufferDeamon *bufferDaemon = (RMFBufferDeamon *)userData;
  [bufferDaemon update:eventFlags];
}

@implementation RMFBufferDeamon

- (id)init {
  self = [super init];
  if (self) {
    _watchedDisks = [[NSMutableSet alloc] init];
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

    [self clearWatchedPaths];
    for(RMFRamdisk *ramdisk in mountedRamdisks) {
      // enable buffer for all files on ramdisk ... potentially dangerous?
    }
  }
}

# pragma mark callback handling
- (void)update:(const FSEventStreamEventFlags[])flags {
  /*
   We receive events for paths that we watch
   
   Handle root changes (= renaming)
   Handle unmountings (> remove from watchlist)
   Update buffer on new files
   
   Ignore Mount, Removal (nothing to do there)
   */
  NSUInteger flagCount = sizeof(*flags) / sizeof(FSEventStreamEventFlags);
  for(NSUInteger index = 0; index < flagCount; index++) {
    FSEventStreamEventFlags aFlag = flags[index];
    switch (aFlag) {
      case kFSEventStreamEventFlagRootChanged:
        // TODO
        break;
      case kFSEventStreamEventFlagUnmount:
        // TODO
        break;
      default:
        break;
    }
  }
}

- (void)updateCallback {
  
  // Unshedule the Eventstream callback but remmber the last eventID
  if( _eventStream != NULL ) {
    FSEventStreamStop(_eventStream);
    FSEventStreamUnscheduleFromRunLoop(_eventStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    self.lastEventId = FSEventStreamGetLatestEventId(_eventStream);
    FSEventStreamRelease(_eventStream);
    _eventStream = NULL;
  }
  else {
    self.lastEventId = FSEventsGetCurrentEventId();
  }
  
  // We got no paths to watch, leave
  if([self.watchedDisks count] == 0) {
    return; // nothing to watch
  }
  
  // We got some paths to watch so generate a new callback
  FSEventStreamContext context = {0, (void *)self, NULL, NULL, NULL};
  const NSTimeInterval latency = 2.0;
  const FSEventStreamCreateFlags flags = (kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagUseCFTypes);
  _eventStream = FSEventStreamCreate(NULL,
                                     &fileSystemEventCallback,
                                     &context,
                                     (CFArrayRef)[self.watchedDisks allObjects],
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
    [self addWatchedPath:[ramdisk.volumeURL path]];
  }
}

- (void)didUnmountRamdisk:(NSNotification *)notification {
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:kRMFRamdiskKey];
  if(ramdisk != nil) {
    [self removeWatchedPath:[ramdisk.volumeURL path]];
  }
}

- (void)didRenameRamdisk:(NSNotification *)notification {
  NSString *oldLabel = [[[notification userInfo] objectForKey:kRMFOldRamdiskLabelKey] stringAsVolumePath];
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:kRMFRamdiskKey];
  if(ramdisk != nil) {
    [self removeWatchedPath:[oldLabel stringAsVolumePath]];
    [self addWatchedPath:[ramdisk.volumeURL path]];
  }
}

#pragma mark Buffer handling
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk {
  
  NSString *path = [ramdisk.volumeURL path];
  if( shouldBuffer ) {
    [self addWatchedPath:path];
  }
  else {
    [self removeWatchedPath:path];
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

- (void)addWatchedPath:(NSString *)path {
  // Add the volume path to the watched paths
  BOOL isDirectory = NO;
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
  if( ! fileExists || ! isDirectory ) {
    return; // ramdisk path is not valid
  }
  
  // Insert path into watched paths
  if(![self.watchedDisks containsObject:path]) {
    return; // path is already in watchlist
  }
  [self.watchedDisks addObject:path];
  [self updateCallback];
}

- (void)clearWatchedPaths {
  [self.watchedDisks removeAllObjects];
  [self updateCallback];
}

- (void)removeWatchedPath:(NSString *)path {
  if([self.watchedDisks containsObject:path]) {
    [self.watchedDisks removeObject:path];
    [self updateCallback];
  }
}

- (void)shouldBuffer:(BOOL)shouldBuffer file:(NSString *)file {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(NO == [fileManager fileExistsAtPath:file]) {
    return; // No valid file found
  }
  
  // Convert String to C useable char array
  //char filename[1024];
  
  const int fileDesciptor= open([file UTF8String], O_RDONLY);
  if(fileDesciptor >= 0) {
    if(shouldBuffer)
      fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 0); // Turn UBC on
    else {
      fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 1); // Turn UBC off
    }
    close(fileDesciptor);
  }
  else {
    NSString *actionString = (shouldBuffer ? @"enable" : @"disable");
    NSLog(@"%@: Could not %@ cache for file %@ becaus the File could not be found!", self, actionString, file );
  }
}
@end

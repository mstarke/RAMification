//
//  RMFFileEventsWatcher.m
//  RAMification
//
//  Created by michael starke on 11.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFileEventsWatcher.h"

#import "RMFMountWatcher.h"
#import "RMFRamdisk.h"

NSString *const RMFDidCreateFileOnRamdiskNotification = @"RMFDidCreateFileOnRamdiskNotification";
NSString *const RMFDidChangeRamdiskFinderLabelNotification =@"RMFDidChangeRamdiskFinderLabelNotification";

@interface RMFFileEventsWatcher () {
  FSEventStreamRef _eventStream;
}

@property (retain) NSMutableSet *watchedURLs;
@property (assign) FSEventStreamEventId lastEventId;

- (void)eventsAtPath:(NSArray *)paths flags:(const FSEventStreamEventFlags[])flags;
- (void)didUnmountRamdisk:(NSNotification *)notification;
- (void)didMountRamdisk:(NSNotification *)notification;
- (void)didRenameRamdisk:(NSNotification *)notification;
- (void)updateCallback;
- (void)addWatchedURL:(NSURL *)url;
- (void)clearWatchedURLs;
- (void)removeWatchedURL:(NSURL *)url;

@end

/*
 FSEvent callback bridign to RMFFileEventsWatcher
 */
static void fileSystemEventCallback(ConstFSEventStreamRef streamRef
                                    , void *userData
                                    , size_t numEvents
                                    , void *eventPaths
                                    , const FSEventStreamEventFlags eventFlags[]
                                    , const FSEventStreamEventId eventIds[]) {
  RMFFileEventsWatcher *fileEventsWatcher = (RMFFileEventsWatcher *)userData;
  [fileEventsWatcher eventsAtPath:(NSArray *)eventPaths flags:eventFlags];
}

@implementation RMFFileEventsWatcher

- (id)init
{
  self = [super init];
  if (self) {
    _watchedURLs = [[NSMutableSet alloc] init];
    _eventStream = NULL;
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(didMountRamdisk:) name:RMFDidMountRamdiskNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didUnmountRamdisk:) name:RMFDidUnmountRamdiskNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didRenameRamdisk:) name:RMFDidRenameRamdiskNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

# pragma mark Notifictaions
- (void)didMountRamdisk:(NSNotification *)notification {
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:kRMFMountWatcherRamdiskKey];
  if(ramdisk != nil) {
    [self addWatchedURL:ramdisk.volumeURL];
  }
}

- (void)didUnmountRamdisk:(NSNotification *)notification {
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:kRMFMountWatcherRamdiskKey];
  if(ramdisk != nil) {
    [self removeWatchedURL:ramdisk.volumeURL];
  }
}

- (void)didRenameRamdisk:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSURL *oldURL = [userInfo objectForKey:kRMFRamdiskVolumeURLBeforeRenameKey];
  RMFRamdisk *ramdisk = [userInfo objectForKey:kRMFMountWatcherRamdiskKey];
  
  if(ramdisk != nil) {
    [self removeWatchedURL:oldURL];
    [self addWatchedURL:ramdisk.volumeURL];
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

@end

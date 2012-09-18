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
@property (assign) NSDate *lastUpdate;

- (void)update;
- (void)didUnmountRamdisk:(NSNotification *)notification;
- (void)didMountRamdisk:(NSNotification *)notification;
- (void)didRenameRamdisk:(NSNotification *)notification;
- (void)updateCallback;
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk;
- (void)addWatchedPath:(NSString *)path;
- (void)removeWatchedPath:(NSString *)path;
- (void)disableCache:(BOOL)disable forPath:(NSString*)file;
@end


static void fileSystemEventCallback(ConstFSEventStreamRef streamRef,
                                    void *userData,
                                    size_t numEvents,
                                    void *eventPaths,
                                    const FSEventStreamEventFlags eventFlags[],
                                    const FSEventStreamEventId eventIds[])
{
  RMFBufferDeamon *bufferDaemon = (RMFBufferDeamon *)userData;
  [bufferDaemon update];
}

@implementation RMFBufferDeamon

- (id)init {
  self = [super init];
  if (self) {
    _watchedDisks = [[NSMutableSet alloc] init];
    _eventStream = NULL;
    _lastUpdate = [[NSDate alloc] init];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    //[defaultCenter addObserver:self selector:@selector(update) name:NSUserDefaultsDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didMountRamdisk:) name:RMFDidMountRamdiskNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didUnmountRamdisk:) name:RMFDidUnmountRamdiskNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didRenameRamdisk:) name:RMFDidRenameRamdiskNotification object:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)update {
  //BOOL shouldBuffer = [[NSUserDefaults standardUserDefaults] boolForKey:RMFSettingsKeyDisableUnifiedBuffer];
  
  RMFFavouritesManager *favoriteManager = [RMFFavouritesManager sharedManager];
  NSArray *mountedFavourites = [favoriteManager mountedFavourites];
  for(RMFRamdisk *ramdisk in mountedFavourites) {
    //[self setShouldBuffer:shouldBuffer forRamdisk:ramdisk];
  }
  NSLog(@"Updating buffer");
  // test for changed files
  self.lastUpdate = [NSDate date];
}

- (void)updateCallback {
  // remove possible old
  FSEventStreamEventId lastEventId = FSEventsGetCurrentEventId();
  if( _eventStream != NULL ) {
    lastEventId = FSEventStreamGetLatestEventId(_eventStream);
    FSEventStreamStop(_eventStream);
    FSEventStreamUnscheduleFromRunLoop(_eventStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    FSEventStreamRelease(_eventStream);
    _eventStream = NULL;
  }
  FSEventStreamContext context = { 0, (void *)self, NULL, NULL, NULL };
  NSTimeInterval latency = 2.0;
  
  _eventStream = FSEventStreamCreate(NULL,
                                     &fileSystemEventCallback,
                                     &context,
                                     (CFArrayRef)[self.watchedDisks allObjects],
                                     lastEventId,
                                     (CFTimeInterval)latency,
                                     kFSEventStreamCreateFlagUseCFTypes);
  FSEventStreamScheduleWithRunLoop(_eventStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
  FSEventStreamStart(_eventStream);
}

- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk {
  
  NSString *path = [ramdisk.label volumePath];
  if( shouldBuffer ) {
    [self addWatchedPath:path];
  }
  else {
    [self removeWatchedPath:path];
  }
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *volumePath = [ramdisk.label volumePath];
  NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:volumePath];
  NSString *file;
  while( file = [dirEnumerator nextObject] ) {
    [self disableCache:(!shouldBuffer) forPath:file];
  }
}

- (void)didMountRamdisk:(NSNotification *)notification {
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:RMFRamdiskKey];
  if(ramdisk != nil) {
    [self addWatchedPath:[ramdisk.label volumePath]];
  }
}

- (void)didUnmountRamdisk:(NSNotification *)notification {
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:RMFRamdiskKey];
  if(ramdisk != nil) {
    [self removeWatchedPath:[ramdisk.label volumePath]];
  }
}

- (void)didRenameRamdisk:(NSNotification *)notification {
  NSString *oldLabel = [[[notification userInfo] objectForKey:RMFOldRamdiskLabelKey] volumePath];
  RMFRamdisk *ramdisk = [[notification userInfo] objectForKey:RMFRamdiskKey];
  if(ramdisk != nil) {
    [self removeWatchedPath:[oldLabel volumePath]];
    [self addWatchedPath:[ramdisk.label volumePath]];
  }
}

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

- (void)removeWatchedPath:(NSString *)path {
  if([self.watchedDisks containsObject:path]) {
    [self.watchedDisks removeObject:path];
    [self updateCallback];
  }
}

- (void)disableCache:(BOOL)disable forPath:(NSString *)file {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(NO == [fileManager fileExistsAtPath:file]) {
    return; // No valid file found
  }
  
  // Convert String to C useable char array
  char filename[1024];
  [file getCString:filename maxLength:1024 encoding:NSUTF8StringEncoding];
  
  int fileDesciptor= open(filename, O_RDONLY);
  if (fileDesciptor == 0) {
    if (disable)
      fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 1); // Turn UBC off
  }
  else {
    fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 0); // Turn UBC on
  }
  close(fileDesciptor);
}
@end

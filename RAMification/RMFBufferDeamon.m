//
//  RMFBufferDeamon.m
//  RAMification
//
//  Created by michael starke on 06.09.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFBufferDeamon.h"

#import "RMFFavoriteManager.h"
#import "RMFRamdisk.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"

@interface RMFBufferDeamon ()
@property (retain) NSMutableSet *watchedDisks;

- (void)update;
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk;
- (void)watchRamdisk:(RMFRamdisk *)ramdisk;
- (void)unwatchRamdisk:(RMFRamdisk *)ramdisk;
- (void)disableCache:(BOOL)disable forFile:(NSString*)file;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSUserDefaultsDidChangeNotification object:nil];
  }
  return self;
}

- (void)update {
  BOOL shouldBuffer = [[NSUserDefaults standardUserDefaults] boolForKey:RMFSettingsKeyDisableUnifiedBuffer];
  
  RMFFavoriteManager *favoriteManager = [RMFFavoriteManager manager];
  NSArray *mountedFavourites = [favoriteManager mountedFavourites];
  for(RMFRamdisk *ramdisk in mountedFavourites) {
    [self setShouldBuffer:shouldBuffer forRamdisk:ramdisk];
  }
}

- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk {
  
  shouldBuffer ? [self watchRamdisk:ramdisk] : [self unwatchRamdisk:ramdisk];
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *volumePath = [ramdisk.label volumePath];
  NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:volumePath];
  NSString *file;
  while( file = [dirEnumerator nextObject] ) {
    [self disableCache:(!shouldBuffer) forFile:file];
  }
}

- (void)watchRamdisk:(RMFRamdisk *)ramdisk {
  [_watchedDisks addObject:ramdisk];
  FSEventStreamContext context = { 0, (void *)self, NULL, NULL, NULL };
  NSTimeInterval latency = 2.0;
  FSEventStreamRef streamRef = FSEventStreamCreate(NULL,
                                                       &fileSystemEventCallback,
                                                       &context,
                                                       (CFArrayRef)[NSArray arrayWithObject:[ramdisk.label volumePath]],
                                                       FSEventsGetCurrentEventId(),
                                                       (CFTimeInterval)latency,
                                                       kFSEventStreamCreateFlagUseCFTypes);
  FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
  FSEventStreamStart(streamRef);
}

- (void)unwatchRamdisk:(RMFRamdisk *)ramdisk {
  [_watchedDisks removeObject:ramdisk];
}

- (void)disableCache:(BOOL)disable forFile:(NSString *)file {
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

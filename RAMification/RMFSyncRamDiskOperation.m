//
//  RMFSyncRamDiskOperation.m
//  RAMification
//
//  Created by Michael Starke on 08.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSyncRamDiskOperation.h"

#import "RMFRamdisk.h"
#import "RMFAppDelegate.h"
#import "RMFSettingsController.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"

@interface RMFSyncRamDiskOperation ()
@property (retain) RMFRamdisk *ramdisk;
@property (assign) RMFSyncMode syncMode;
@end

@implementation RMFSyncRamDiskOperation

@synthesize ramdisk = _ramdisk;
@synthesize syncMode = _syncMode;

- (id)init {
  self = [self initWithRamdisk:nil mode:RMFSyncModeNone];
  return self;
}

- (id)initWithRamdisk:(RMFRamdisk *)ramdisk mode:(RMFSyncMode)syncMode {
  self = [super init];
  if (self) {
    self.ramdisk = ramdisk;
    self.syncMode = syncMode;
  }
  return self;
}

- (void)main {
  if( self.isCancelled ) {
    NSLog(@"Synchronization got canceled!");
    return;
  }
  
  if(self.ramdisk == nil || self.syncMode == RMFSyncModeNone || self.ramdisk.isMounted == NO ) {
    NSLog(@"Synchronization was aborted due to wrong status of ramdisk!");
    return;
  }
  
  /* Create an autorelease pool and build the correct rsync operation */
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *backupPath = [[[NSUserDefaults standardUserDefaults] stringForKey:RMFSettingsKeyBackupPath] stringByAppendingString:self.ramdisk.label];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL isDirectory = false;
  BOOL isPresent= [fileManager fileExistsAtPath:backupPath isDirectory:&isDirectory];
  // The Path is not there
  if(NO == (isPresent && isDirectory)) {
    NSError *error = nil;
    [fileManager createDirectoryAtPath:backupPath withIntermediateDirectories:YES attributes:nil error:&error];
    if(nil != error) {
      NSLog( @"Stopping %@ because of error %@", self, error );
      return;
    }
  }
  NSString *sourcePath = [self.ramdisk.label volumePath];
  NSArray *arguments = [NSArray arrayWithObjects:@"-a", sourcePath, backupPath, nil];
  /* Setup the rsycn task and run it */
  NSTask *rsync = [[NSTask alloc] init];
  [rsync setLaunchPath:@"/usr/bin/rsync"];
  [rsync setArguments:arguments];
  [rsync launch];
  [rsync waitUntilExit];
  NSLog(@"%@ finished with exit code %d", [rsync launchPath], [rsync terminationStatus]);
  [rsync release];
  [pool drain];
}

@end

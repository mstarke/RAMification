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
  self.ramdisk.activity = RMFRamdiskIdle;
  if( self.isCancelled ) {
    NSLog(@"Synchronization got canceled!");
    return;
  }
  
  if(self.ramdisk == nil || self.syncMode == RMFSyncModeNone || self.ramdisk.isMounted == NO ) {
    NSLog(@"Synchronization was aborted due to wrong status of ramdisk!");
    return;
  }
  switch (self.syncMode) {
    case RMFSyncModeBackup:
      self.ramdisk.activity = RMFRamdiskBackup;
      break;
    case RMFSyncModeRestore:
      self.ramdisk.activity = RMFRamdiskRestoring;
      break;
    case RMFSyncModeNone:
      self.ramdisk.activity = RMFRamdiskIdle;
      break;
  }
  /* Create an autorelease pool and build the correct rsync operation */
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // We create the backup folder on restore and on sync
  // It might be better to just create the folder if we actually need it - that it on backup not on restore
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
  // in restore mode, we sync from backup to ramdisk
  // in backup mode, we sync from ramdisk to backup
  NSArray *arguments= nil;
  if( self.syncMode == RMFSyncModeBackup) {
    arguments = [NSArray arrayWithObjects:@"-a", "--delete", sourcePath, backupPath, nil];
  }
  else {
    arguments = [NSArray arrayWithObjects:@"-a", backupPath, sourcePath, nil];
  }
  /* Setup the rsycn task and run it */
  NSTask *rsync = [[NSTask alloc] init];
  [rsync setLaunchPath:@"/usr/bin/rsync"];
  [rsync setArguments:arguments];
  [rsync launch];
  [rsync waitUntilExit];
  self.ramdisk.activity = RMFRamdiskIdle;
  NSLog(@"%@ finished with exit code %d", [rsync launchPath], [rsync terminationStatus]);
  [rsync release];
  [pool drain];
}

@end

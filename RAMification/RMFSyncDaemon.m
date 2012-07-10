//
//  RMFSyncDaemon.m
//  RAMification
//
//  Created by Michael Starke on 17.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSyncDaemon.h"

#import "RMFRamdisk.h"
#import "RMFAppDelegate.h"
#import "RMFSyncRamDiskOperation.h"
#import "RMFSettingsKeys.h"

#import <DiskArbitration/DiskArbitration.h>

@interface RMFSyncDaemon ()
@property (assign) DAApprovalSessionRef approvalSession;
@property (retain) NSMutableDictionary *enabledBackups;
@property (retain) NSOperationQueue *queue;
@property (retain) NSTimer *backupTimer;
- (void) performBackup;
- (BOOL) canUnmount:(RMFRamdisk *)ramdisk;
- (void) unregisterCallbackForRamdisk:(RMFRamdisk *)ramdisk;
- (void) registerCallbackForRamdisk:(RMFRamdisk *)ramdisk;
- (void) backupRamdisk:(RMFRamdisk *)ramdisk;
- (void) disableTimer;
- (void) enableTimer;
- (RMFRamdisk *) findRamdiskByName:(NSString *)name;
@end

/* static callback for removal */
static DADissenterRef unmountCallback(DADiskRef disk, void * context)
{
  RMFSyncDaemon *syncDamon = (RMFSyncDaemon *)context;
  NSDictionary *description = (NSDictionary *) DADiskCopyDescription(disk);
  RMFRamdisk *ramdisk = [syncDamon findRamdiskByName:[description objectForKey:(NSString *)kDADiskDescriptionVolumeNameKey]];
  BOOL isReady = [syncDamon canUnmount:ramdisk];
  if (isReady) {
    return NULL;
  }
  else {
    return DADissenterCreate(CFAllocatorGetDefault(), kDAReturnBusy,	CFSTR("Device is still in Use")); 
  }
}

@implementation RMFSyncDaemon

@synthesize approvalSession = _approvalSession;
@synthesize enabledBackups = _enabledBackups;
@synthesize queue = _queue;
@synthesize backupTimer;

- (id)init {
  self = [super init];
  if (self) {
    _enabledBackups = [[NSMutableDictionary alloc] init];
    _queue = [[NSOperationQueue alloc] init];
  }
  return self;
}

- (void)dealloc {
  // unregister and cleanup
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
  self.enabledBackups = nil;
  self.queue = nil;
  [super dealloc];
}

- (void)performBackup {
  // Iterate over all our registerd backups
  for(NSValue *ramdiskId in self.enabledBackups) {
    RMFRamdisk *ramdisk = [[self.enabledBackups objectForKey:ramdiskId] nonretainedObjectValue];
    [self backupRamdisk:ramdisk];
  }
}

- (BOOL)canUnmount:(RMFRamdisk *)ramdisk {
  NSLog(@"Got called as unmount callback!");
  return YES;
}

- (void)disableBackupForRamdisk:(RMFRamdisk *)ramdisk {
  [self.enabledBackups removeObjectForKey:ramdisk.label];
  if( [self.enabledBackups count] == 0 ) {
    [self unregisterCallbackForRamdisk:ramdisk];
  }
}

- (void)enableBackupForRamdisk:(RMFRamdisk *)ramdisk {
  [self.enabledBackups setObject:[NSValue valueWithNonretainedObject:ramdisk] forKey:ramdisk.label];
  if( [self.enabledBackups count] == 1 ) {
    [self registerCallbackForRamdisk:ramdisk];
  }
}

- (void)registerCallbackForRamdisk:(RMFRamdisk *)ramdisk {
  // register for callbacks
  _approvalSession = DAApprovalSessionCreate(CFAllocatorGetDefault());
  DAApprovalSessionScheduleWithRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  // create description dictionory to just match the volumes names that are equal to the ramdisks label
  NSDictionary *description = [NSDictionary dictionaryWithObjectsAndKeys:ramdisk.label, (NSString *)kDADiskDescriptionVolumeNameKey, nil];
  DARegisterDiskUnmountApprovalCallback(self.approvalSession, (CFDictionaryRef)description, unmountCallback, self);
}

- (void)unregisterCallbackForRamdisk:(RMFRamdisk *)ramdisk {
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
}

- (void)backupRamdisk:(RMFRamdisk *)ramdisk {
  /*
   If the disk is not enabled for backup we do nothing
   */
  if (ramdisk.isBackupEnabled == NO) {
    return; // Stop synchronizeation we got a wrong ramdisk
  }
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:RMFSyncModeBackup];
  [self.queue addOperation:operation];
  [operation release];
}

- (void)restoreRamdisk:(RMFRamdisk *)ramdisk {
  /*
   If we have no backup for the ramdisk enabled there is no need to restore the ramdisk
   */
  if(ramdisk.isBackupEnabled == NO ) {
    return;
  }
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:RMFSyncModeRestore];
  [self.queue addOperation:operation];
  [self.queue name];
  [operation release];
}

- (RMFRamdisk *)findRamdiskByName:(NSString *)name {
  return [[self.enabledBackups objectForKey:name] nonretainedObjectValue];
}

- (void)backupIntervallChanged:(NSUInteger)interval {
  NSTimeInterval timeInterval = interval;
  [self disableTimer];
  self.backupTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(performBackups) userInfo:nil repeats:YES];
}

- (void)disableTimer {
  if (self.backupTimer != nil) {
    [self.backupTimer invalidate];
    self.backupTimer = nil;
  }
}

- (void)enableTimer {
  NSTimeInterval interval = [[[NSUserDefaultsController sharedUserDefaultsController] valueForKey:RMFSettingsKeyBackupInterval] doubleValue];
  if (self.backupTimer != nil) {
    interval = [self.backupTimer timeInterval];
    [self.backupTimer invalidate];
    self.backupTimer = nil;
  }
  [self backupIntervallChanged:interval];
}

@end

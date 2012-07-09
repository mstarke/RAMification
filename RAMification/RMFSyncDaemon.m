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

#import <DiskArbitration/DiskArbitration.h>

@interface RMFSyncDaemon ()
@property (assign) DAApprovalSessionRef approvalSession;
@property (retain) NSMutableDictionary *enabledBackups;
@property (retain) NSOperationQueue *queue;
- (BOOL) canUnmount:(RMFRamdisk *)ramdisk;
- (void) unregisterCallback;
- (void) registerCallback;
- (void) synchronize:(RMFRamdisk *)ramdisk;
- (RMFRamdisk *) findRamdiskByName:(NSString *)name;
@end

/* static callback for removal */
static DADissenterRef unmountCallback(DADiskRef disk, void * context)
{
  RMFSyncDaemon *syncDamon = (RMFSyncDaemon *)context;
  NSString *bsdName = [NSString stringWithUTF8String:DADiskGetBSDName(disk)];
  DADiskGetOptions(disk);
  NSLog(@"%@", bsdName);
  RMFRamdisk *ramdisk = [syncDamon findRamdiskByName:bsdName];
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

- (id)init {
  self = [super init];
  if (self) {
    _enabledBackups = [[NSMutableDictionary alloc] init];
    _queue = [[NSOperationQueue alloc] init];
    [self registerCallback];
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

- (BOOL)canUnmount:(RMFRamdisk *)ramdisk {
  NSLog(@"Got called as unmount callback!");
  return YES;
}

- (void)disableBackupForRamdisk:(RMFRamdisk *)ramdisk {
  [self.enabledBackups removeObjectForKey:ramdisk.label];
  if( [self.enabledBackups count] == 0 ) {
    [self unregisterCallback];
  }
}

- (void)enableBackupForRamdisk:(RMFRamdisk *)ramdisk {
  [self.enabledBackups setObject:[NSValue valueWithNonretainedObject:ramdisk] forKey:ramdisk.label];
  if( [self.enabledBackups count] == 1 ) {
    [self registerCallback];
  }
}

- (void)registerCallback {
  // register for callbacks
  _approvalSession = DAApprovalSessionCreate(CFAllocatorGetDefault());
  DAApprovalSessionScheduleWithRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  DARegisterDiskUnmountApprovalCallback(self.approvalSession, NULL, unmountCallback, self);
  
}

- (void)unregisterCallback {
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
}

- (void)synchronize:(RMFRamdisk *)ramdisk {
  if (ramdisk.isBackupEnabled == NO) {
    return; // Stop synchronizeation we got a wrong ramdisk
  }
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:RMFSyncModeBackup];
  [self.queue addOperation:operation];
  [operation release];
}

- (void)restoreRamdisk:(RMFRamdisk *)ramdisk {
  if(ramdisk.isBackupEnabled == NO ) {
    return;
  }
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:RMFSyncModeRestore];
  [self.queue addOperation:operation];
  [self.queue name];
  [operation release];
}

- (RMFRamdisk *)findRamdiskByName:(NSString *)name {
  return nil;
}

@end

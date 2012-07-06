//
//  RMFSyncDaemon.m
//  RAMification
//
//  Created by Michael Starke on 17.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSyncDaemon.h"

#import "RMFRamdisk.h"

#import <DiskArbitration/DiskArbitration.h>
#import <DiskArbitration/DADissenter.h>
#import <DiskArbitration/DASession.h>


@interface RMFSyncDaemon ()
@property (assign) DAApprovalSessionRef approvalSession;
@property (retain) NSMutableDictionary *enabledBackups;
- (void) unmountCallback;
- (void) unregisterCallback;
- (void) registerCallback;
@end

/* static callback for removal */
static DADissenterRef unmountCallback(DADiskRef disk, void * context)
{
  RMFSyncDaemon *syncDamon = (RMFSyncDaemon *)context;
  [syncDamon unmountCallback];
  return NULL;
  //DADissenterCreate(CFAllocatorGetDefault(), kDAReturnBusy,	CFSTR("No!"));
}

@implementation RMFSyncDaemon

@synthesize approvalSession = _approvalSession;
@synthesize enabledBackups = _enabledBackups;

- (id)init
{
  self = [super init];
  if (self) {
    _enabledBackups = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc
{
  // unregister and cleanup
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
  [super dealloc];
}

- (void)unmountCallback
{
  NSLog(@"Got called as unmount callback!");
}

- (void)disableBackupForRamdisk:(RMFRamdisk *)ramdisk
{
  [self.enabledBackups removeObjectForKey:ramdisk.label];
  if( [self.enabledBackups count] == 0 )
  {
    [self unregisterCallback];
  }
}

- (void)enableBackupForRamdisk:(RMFRamdisk *)ramdisk
{
  [self.enabledBackups setObject:[NSValue valueWithNonretainedObject:ramdisk] forKey:ramdisk.label];
  if( [self.enabledBackups count] == 1 )
  {
    [self registerCallback];
  }
}

- (void)registerCallback
{
  // register for callbacks
  _approvalSession = DAApprovalSessionCreate(CFAllocatorGetDefault());
  DAApprovalSessionScheduleWithRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  DARegisterDiskUnmountApprovalCallback(self.approvalSession, NULL, unmountCallback, self);

}

- (void)unregisterCallback
{
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
}

@end

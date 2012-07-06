//
//  RMFSyncDaemon.m
//  RAMification
//
//  Created by Michael Starke on 17.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSyncDaemon.h"

#import <DiskArbitration/DiskArbitration.h>
#import <DiskArbitration/DADissenter.h>
#import <DiskArbitration/DASession.h>


@interface RMFSyncDaemon ()

- (void) unmountCallback;

@end

// Callback for a pending unmount
static DADissenterRef unmountCallback(DADiskRef disk, void * context)
{
  RMFSyncDaemon *syncDamon = (RMFSyncDaemon *)context;
  [syncDamon unmountCallback];
  return NULL;
  //DADissenterCreate(CFAllocatorGetDefault(), kDAReturnBusy,	CFSTR("No!"));
}

@implementation RMFSyncDaemon

- (id)init
{
  self = [super init];
  if (self) {
    DAApprovalSessionRef approvalSession = DAApprovalSessionCreate(CFAllocatorGetDefault());
    DAApprovalSessionScheduleWithRunLoop(approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    DARegisterDiskUnmountApprovalCallback(approvalSession, NULL, unmountCallback, self);
  }
  return self;
}

- (void)unmountCallback
{
  NSLog(@"Got called as unmount callback!");
}


@end

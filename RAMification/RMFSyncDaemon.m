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
#import "RMFFavoriteManager.h"
#import "RMFSyncRamDiskOperation.h"
#import "RMFSettingsKeys.h"

#import <DiskArbitration/DiskArbitration.h>

@interface RMFSyncDaemon ()
@property (assign) DAApprovalSessionRef approvalSession;
@property (retain) NSOperationQueue *queue;
@property (retain) NSTimer *backupTimer;
- (void) performBackup;
- (BOOL) canUnmount:(RMFRamdisk *)ramdisk;
- (void) unregisterCallbackForRamdisk:(RMFRamdisk *)ramdisk;
- (void) registerCallbackForRamdisk:(RMFRamdisk *)ramdisk;
- (void) backupRamdisk:(RMFRamdisk *)ramdisk;
- (void) disableTimer;
- (void) enableTimer;
@end

/* static callback for removal */
static DADissenterRef unmountCallback(DADiskRef disk, void * context)
{
  RMFSyncDaemon *syncDamon = (RMFSyncDaemon *)context;
  RMFFavoriteManager *favouriteManager = ((RMFAppDelegate *)[NSApp delegate]).favoritesManager;
  NSString *bsdName = [NSString stringWithUTF8String:DADiskGetBSDName(disk)];
  RMFRamdisk *ramdisk = [favouriteManager findFavouriteForDevicePath:bsdName];
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
@synthesize queue = _queue;
@synthesize backupTimer;

- (id)init {
  self = [super init];
  if (self) {
    _queue = [[NSOperationQueue alloc] init];
  }
  return self;
}

- (void)dealloc {
  // unregister and cleanup
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
  self.queue = nil;
  [super dealloc];
}

- (void)performBackup {
  // Ask the favourites manager for all mounted favourties
  // and iterate over them to back them up
  RMFFavoriteManager *favouriteManager = ((RMFAppDelegate *)[NSApp delegate]).favoritesManager;
  NSArray *mountedDisk = [[favouriteManager mountedFavourites] retain];
  NSArray *backupDisks = [mountedDisk filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return ((RMFRamdisk *)evaluatedObject).isBackupEnabled;
  }]];
  for(RMFRamdisk *ramdisk in backupDisks) {
    [self backupRamdisk:ramdisk];
  }
}

- (BOOL)canUnmount:(RMFRamdisk *)ramdisk {
  
  if(ramdisk.isBackupEnabled == NO) {
    return YES; // Disk with no backusp can always be unmounted
  }
  NSArray *backups = [[self.queue operations] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id operation, NSDictionary *bindings) {
    return [((RMFSyncRamDiskOperation *)operation).ramdisk isEqual:ramdisk];
  }]];
  BOOL hasNoPendingBackups = ([backups count] == 0); 
  return hasNoPendingBackups;
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
  [operation release];
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

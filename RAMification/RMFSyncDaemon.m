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
#import "RMFFavouritesManager.h"
#import "RMFSyncRamDiskOperation.h"
#import "RMFMountWatcher.h"
#import "RMFSettingsKeys.h"

#import <CoreFoundation/CoreFoundation.h>
#import <DiskArbitration/DiskArbitration.h>

@interface RMFSyncDaemon ()

@property (assign) DAApprovalSessionRef approvalSession;
@property (retain) NSOperationQueue *queue;
@property (retain) NSTimer *backupTimer;

/* callback */
- (BOOL)canUnmount:(RMFRamdisk *)ramdisk;
- (void)unregisterCallbackForRamdisk:(RMFRamdisk *)ramdisk;
- (void)registerCallbackForRamdisk:(RMFRamdisk *)ramdisk;
/* backup */
- (void)performBackup;
- (void)backupRamdisk:(RMFRamdisk *)ramdisk;
- (void)restoreRamdisk:(RMFRamdisk *)ramdisk;
/* timer */
- (void)disableTimer;
- (void)enableTimer;
/* notifications*/
- (void)didMountFavourite:(NSNotification *)notification;
- (void)userDefaultsDidChange:(NSNotification *)notification;

// This message should be sent to the sync deamon to update the backup intervall
- (void)backupIntervallChanged:(NSUInteger )interval;
@end

// Static callback to be used to pipe the call back to the foundation object
static DADissenterRef createUnmountReply(DADiskRef disk, void * context)
{
  RMFSyncDaemon *syncDamon = (RMFSyncDaemon *)context;
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  NSString *bsdName = [NSString stringWithUTF8String:DADiskGetBSDName(disk)];
  RMFRamdisk *ramdisk = [favouriteManager findFavouriteWithBsdDevice:bsdName];
  BOOL isReady = [syncDamon canUnmount:ramdisk];
  if (isReady) {
    return NULL;
  }
  else {
    return DADissenterCreate(CFAllocatorGetDefault(), kDAReturnBusy,	CFSTR("Device is still in Use")); 
  }
}

@implementation RMFSyncDaemon

#pragma mark Lifecylce

- (id)init {
  self = [super init];
  if (self) {
    _queue = [[NSOperationQueue alloc] init];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didMountFavourite:) name:RMFDidMountRamdiskNotification object:nil];
    
    [self enableTimer];
    NSLog(@"Created %@", self);
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // unregister for mount/unmount callbacks
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
  self.queue = nil;
  
  [super dealloc];
}

#pragma mark Callbacks
- (BOOL)canUnmount:(RMFRamdisk *)ramdisk {
  
  NSLog(@"%@: Trying to unmount %@", self, ramdisk);
  BOOL (^isEqualBlock)(id, NSDictionary *);
  isEqualBlock = ^BOOL(id operation,NSDictionary *bindings){
    return [((RMFSyncRamDiskOperation *)operation).ramdisk isEqual:ramdisk];
  };
  
  if(ramdisk.backupMode == RMFNoBackup) {
    NSLog(@"%@: No Backups needed for %@. Good to go!", self, ramdisk);
    return YES; // Disk with no backusp can always be unmounted
  }
  NSArray *backups = [[self.queue operations] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:isEqualBlock]];
  BOOL hasNoPendingBackups = ([backups count] == 0);
  // ramdisk has no backups in the loop so we check for the oldest backup
  if(hasNoPendingBackups) {
    NSDate *lastBackup = ramdisk.lastBackupDate;
    NSTimeInterval secondsSinceLastBackup = [lastBackup timeIntervalSinceNow];
    NSLog(@"%@: Last backup was done %f Seconds ago",self, -secondsSinceLastBackup);
    if(secondsSinceLastBackup <= -30) {
      [self backupRamdisk:ramdisk];
      NSLog(@"%@: Backup to old. Scheduling new one. Eject denied!", self);
      return NO;
    }
    NSLog(@"%@: Backup up to date. Free to eject", self);
    return YES;
  }
  NSLog(@"%@: Backup in progress. SchedulingEject denied!", self);
  return NO; // has bending backups, deny eject
}

- (void)registerCallbackForRamdisk:(RMFRamdisk *)ramdisk {
  // register for callbacks
  _approvalSession = DAApprovalSessionCreate(CFAllocatorGetDefault());
  DAApprovalSessionScheduleWithRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  // create description dictionory to just match the volumes names that are equal to the ramdisks label
  // NSDictionary *description = [NSDictionary dictionaryWithObjectsAndKeys:ramdisk.label, (NSString *)kDADiskDescriptionVolumeNameKey, nil];
  DARegisterDiskUnmountApprovalCallback(self.approvalSession, nil, createUnmountReply, self);
}

- (void)unregisterCallbackForRamdisk:(RMFRamdisk *)ramdisk {
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  CFRelease(_approvalSession);
  self.approvalSession = NULL;
}

#pragma mark Backup/Restore
- (void)performBackup {
  
  BOOL (^isBackupBlock)(id,NSDictionary *);
  isBackupBlock = ^BOOL(id ramdisk, NSDictionary *bindings){
    return ((RMFRamdisk *)ramdisk).backupMode == RMFBackupPeriodically; 
  };
  
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];  
  
  NSArray *mountedDisk = [favouriteManager mountedFavourites];
  NSArray *backupDisks = [mountedDisk filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:isBackupBlock]];
 
  NSLog(@"%@: Found %lu mounted Disks. Disks: %@", self, [mountedDisk count], mountedDisk);
  NSLog(@"%@: Found %lu disk that need periodic backups. Disks: %@", self, [backupDisks count], backupDisks);

  for(RMFRamdisk *ramdisk in backupDisks) {
    [self backupRamdisk:ramdisk];
  }
}

- (void)backupRamdisk:(RMFRamdisk *)ramdisk {
  if (ramdisk.backupMode == RMFNoBackup || ramdisk.activity == RMFRamdiskBackup) {
    return; // no backups enabeld or at leas one backup in processs
  }
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:RMFSyncModeBackup];
  [self.queue addOperation:operation];
  [operation release];
}

- (void)restoreRamdisk:(RMFRamdisk *)ramdisk {
  if(ramdisk.backupMode == RMFNoBackup ) {
    return; // No backup enabled so no restore needed
  }
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:RMFSyncModeRestore];
  [self.queue addOperation:operation];
  [operation release];
}

#pragma mark Notifications
- (void)didMountFavourite:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  RMFRamdisk *ramdisk = [userInfo objectForKey:kRMFRamdiskKey];
  
  if(ramdisk == nil) {
    return; // ingoring, no RAM disk present
  }
  
  if(ramdisk.backupMode != RMFNoBackup) {
    NSLog(@"%@: Ramdisk %@ mounted. Restoring content!", self, ramdisk.label);
    [self restoreRamdisk:ramdisk];
    [self registerCallbackForRamdisk:ramdisk];
  }
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
  NSLog(@"%@: Defaults did change", self);
  NSTimeInterval newInterval = [[NSUserDefaults standardUserDefaults] integerForKey:kRMFSettingsKeyBackupInterval];
  
  if(self.backupTimer != nil && self.backupTimer.isValid) {
    // timer is valid
    if([self.backupTimer timeInterval] != newInterval) {
      // but has a different value than the settings
      [self backupIntervallChanged:(NSUInteger)newInterval];
    }
  }
  
}

- (void)backupIntervallChanged:(NSUInteger)interval {
  NSLog(@"%@: Backup intervall changed. Adjusting to new interval %lu", self, interval);
  NSTimeInterval timeInterval = interval;
  [self disableTimer];
  self.backupTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(performBackup) userInfo:nil repeats:YES];
}

# pragma mark Timer
- (void)disableTimer {
  if (self.backupTimer != nil) {
    [self.backupTimer invalidate];
    self.backupTimer = nil;
  }
}

- (void)enableTimer {
  NSUInteger backupInterval = [[NSUserDefaults standardUserDefaults] integerForKey:kRMFSettingsKeyBackupInterval];
  NSTimeInterval interval = backupInterval;
  if (self.backupTimer != nil) {
    interval = [self.backupTimer timeInterval];
    [self.backupTimer invalidate];
    self.backupTimer = nil;
  }
  [self backupIntervallChanged:interval];
}

@end

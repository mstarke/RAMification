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
#import "RMFVolumeObserver.h"
#import "RMFSettingsKeys.h"

#import <CoreFoundation/CoreFoundation.h>
#import <DiskArbitration/DiskArbitration.h>

@interface RMFSyncDaemon ()

@property (nonatomic, strong) __attribute__((NSObject)) DAApprovalSessionRef approvalSession;
@property (strong) NSOperationQueue *queue;
@property (strong) NSTimer *backupTimer;
@property (strong) NSMutableSet *registerdRamdisks;

@end

@implementation RMFSyncDaemon

// Static callback to be used to pipe the call back to the foundation object
static DADissenterRef createUnmountReply(DADiskRef disk, void * context)
{
  RMFSyncDaemon *syncDamon = (__bridge RMFSyncDaemon *)context;
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  NSDictionary *diskInfoDict = (NSDictionary *)CFBridgingRelease(DADiskCopyDescription(disk));
  NSURL *deviceURL = diskInfoDict[(NSString *)kDADiskDescriptionVolumePathKey];
  
  BOOL didReadUUID = NO;
  NSUUID *uuid = [RMFRamdisk uuidOfRamdiskAtAURL:deviceURL success:&didReadUUID];
  
  if(didReadUUID) {
    RMFRamdisk *ramdisk = [favouriteManager findFavouriteByUUID:uuid];
    if(nil != ramdisk) {
      if(NO == [syncDamon canUnmount:ramdisk]) {
        return DADissenterCreate(CFAllocatorGetDefault(), kDAReturnBusy,	CFSTR("Device is still in Use"));
      }
    }
  }
  return NULL;
}

#pragma mark Lifecylce

- (instancetype)init {
  self = [super init];
  if (self) {
    /*
     Setup interal datastructures
     */
    _queue = [[NSOperationQueue alloc] init];
    _registerdRamdisks = [[NSMutableSet alloc] init];
    
    /*
     Register for notifications
     */
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didMountFavourite:) name:RMFVolumeObserverDidMountRamdiskNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(didUnmountFavourite:) name:RMFVolumeObserverDidUnmountRamdiskNotification object:nil];
    
    [self enableTimer];
    NSLog(@"Created %@", self);
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // unregister for mount/unmount callbacks
  DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
  self.approvalSession = NULL;
  
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
    return YES; // Disk with no backups can always be unmounted
  }
  NSArray *backups = [(self.queue).operations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:isEqualBlock]];
  BOOL hasNoPendingBackups = (backups.count == 0);
  // ramdisk has no backups in the loop so we check for the oldest backup
  if(hasNoPendingBackups) {
    NSDate *lastBackup = ramdisk.lastBackupDate;
    NSTimeInterval secondsSinceLastBackup = lastBackup.timeIntervalSinceNow;
    NSLog(@"%@: Last backup was done %f Seconds ago",self, -secondsSinceLastBackup);
    if(secondsSinceLastBackup <= -30 ) {
      [self backupRamdisk:ramdisk ejectVolume:YES];
      NSLog(@"%@: Backup to old. Scheduling new one. Eject denied!", self);
      return NO;
    }
    NSLog(@"%@: Backup up to date. Free to eject", self);
    return YES;
  }
  NSLog(@"%@: Backup in progress. SchedulingEject denied!", self);
  return NO; // has pending backups, deny eject
}

- (void)registerCallbackForRamdisk:(RMFRamdisk *)ramdisk {
  // register for callbacks
  if([self.registerdRamdisks containsObject:ramdisk]) {
    return; // we are already registered
  }
  // we use a brute fore callback, so just callback if we really need to
  if(0 == (self.registerdRamdisks).count) {
    DAApprovalSessionRef session = DAApprovalSessionCreate(CFAllocatorGetDefault());
    self.approvalSession = session;
    CFRelease(session);
    DAApprovalSessionScheduleWithRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    // create description dictionory to just match the volumes names that are equal to the ramdisks label
    // NSDictionary *description = [NSDictionary dictionaryWithObjectsAndKeys:ramdisk.label, (NSString *)kDADiskDescriptionVolumeNameKey, nil];
    DARegisterDiskUnmountApprovalCallback(self.approvalSession, nil, createUnmountReply, (__bridge void *)(self));
  }
  [self.registerdRamdisks addObject:ramdisk];
}

- (void)unregisterCallbackForRamdisk:(RMFRamdisk *)ramdisk {
  
  [self.registerdRamdisks removeObject:ramdisk];
  if(0 == _registerdRamdisks.count && NULL != self.approvalSession) {
    DAApprovalSessionUnscheduleFromRunLoop(self.approvalSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    self.approvalSession = NULL;
  }
}

#pragma mark Backup/Restore
- (void)performBackup {
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  
  NSArray *mountedDisk = [favouriteManager mountedFavourites];
  NSArray *backupDisks = [mountedDisk filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.%@ == %d", NSStringFromSelector(@selector(backupMode)), RMFBackupPeriodically]];
  
  NSLog(@"%@: Found %lu mounted Disks. Disks: %@", self, mountedDisk.count, mountedDisk);
  NSLog(@"%@: Found %lu disk that need periodic backups. Disks: %@", self, backupDisks.count, backupDisks);
  
  for(RMFRamdisk *ramdisk in backupDisks) {
    [self backupRamdisk:ramdisk ejectVolume:NO];
  }
}

- (void)backupRamdisk:(RMFRamdisk *)ramdisk ejectVolume:(BOOL)shouldEject{
  if (ramdisk.backupMode == RMFNoBackup || ramdisk.activity == RMFRamdiskBackup) {
    return; // no backups enabeld or at leas one backup in processs
  }
  RMFSyncMode backupMode = shouldEject ? RMFSyncModeBackupAndEject : RMFSyncModeBackup;
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:backupMode];
  [self.queue addOperation:operation];
}

- (void)restoreRamdisk:(RMFRamdisk *)ramdisk {
  if(ramdisk.backupMode == RMFNoBackup ) {
    return; // No backup enabled so no restore needed
  }
  RMFSyncRamDiskOperation *operation = [[RMFSyncRamDiskOperation alloc] initWithRamdisk:ramdisk mode:RMFSyncModeRestore];
  [self.queue addOperation:operation];
}

#pragma mark Notifications
- (void)didMountFavourite:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  RMFRamdisk *ramdisk = userInfo[RMFVolumeObserverRamdiskKey];
  BOOL mountedOnStartup = [userInfo[RMFVolumeObserverWasAlreadyMountedOnStartupKey] boolValue];
  
  if(ramdisk == nil) {
    return; // ingoring, no RAM disk present
  }
  
  if(ramdisk.backupMode != RMFNoBackup) {
    if(NO == mountedOnStartup) {
      NSLog(@"%@: Ramdisk %@ mounted. Restoring content!", self, ramdisk.label);
      [self restoreRamdisk:ramdisk];
    }
    [self registerCallbackForRamdisk:ramdisk];
  }
}

- (void)didUnmountFavourite:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  RMFRamdisk *ramdisk = userInfo[RMFVolumeObserverRamdiskKey];
  
  if(nil == ramdisk) {
    return; // ramdisk missing.
  }
  [self unregisterCallbackForRamdisk:ramdisk];
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
  NSLog(@"%@: Defaults did change", self);
  NSTimeInterval newInterval = [[NSUserDefaults standardUserDefaults] integerForKey:RMFSettingsKeyBackupInterval];
   
  if(self.backupTimer != nil && self.backupTimer.isValid) {
    // timer is valid
    if((self.backupTimer).timeInterval != newInterval) {
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
  NSUInteger backupInterval = [[NSUserDefaults standardUserDefaults] integerForKey:RMFSettingsKeyBackupInterval];
  NSTimeInterval interval = backupInterval;
  if (self.backupTimer != nil) {
    interval = (self.backupTimer).timeInterval;
    [self.backupTimer invalidate];
    self.backupTimer = nil;
  }
  [self backupIntervallChanged:interval];
}

@end

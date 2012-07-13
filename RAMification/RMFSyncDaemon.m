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

#import <CoreFoundation/CoreFoundation.h>
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
- (void) volumeDidMount:(NSNotification *)notification;
@end

// Static callback to be used to pipe the call back to the foundation object
static DADissenterRef createUnmountReply(DADiskRef disk, void * context)
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
    // Register to the mount events so we can handle restoreation of favourites
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *center = [workspace notificationCenter];
    [center addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
    [self enableTimer];
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

  BOOL (^isBackupBlock)(id,NSDictionary *);
  isBackupBlock = ^BOOL(id ramdisk, NSDictionary *bindings){
    return ((RMFRamdisk *)ramdisk).backupMode == RMFBackupPeriodically; 
  };
  RMFFavoriteManager *favouriteManager = ((RMFAppDelegate *)[NSApp delegate]).favoritesManager;
  if(favouriteManager == nil ) {
    return; // No Manager found, just return (and try agaoin next time)
  }
  NSArray *mountedDisk = [[favouriteManager mountedFavourites] retain];
  NSLog(@"%@: Found %lu mounted Disks. Disks: %@", self, [mountedDisk count], mountedDisk);
  NSArray *backupDisks = [[mountedDisk filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:isBackupBlock]] retain];
  NSLog(@"%@: Found %lu disk that need periodic backups. Disks: %@", self, [backupDisks count], backupDisks);
  [mountedDisk release];
  [backupDisks release];
  for(RMFRamdisk *ramdisk in backupDisks) {
    [self backupRamdisk:ramdisk];
  }
}

- (BOOL)canUnmount:(RMFRamdisk *)ramdisk {
  
  BOOL (^isEqualBlock)(id, NSDictionary *);
  isEqualBlock = ^BOOL(id operation,NSDictionary *bindings){
    return [((RMFSyncRamDiskOperation *)operation).ramdisk isEqual:ramdisk];
  };
  
  if(ramdisk.backupMode == RMFNoBackup) {
    return YES; // Disk with no backusp can always be unmounted
  }
  NSArray *backups = [[self.queue operations] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:isEqualBlock]];
  BOOL hasNoPendingBackups = ([backups count] == 0);
  // ramdisk has no backups in the loop so we check for the oldest backup
  if(hasNoPendingBackups) {
    // The time interval for the last backup should take into account
    // the backup interval since we might overtake ourselves in backups?
    
  }
  return hasNoPendingBackups;
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

- (void)volumeDidMount:(NSNotification *)notification {
  NSString *devicePath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  
  RMFAppDelegate *delegate = [NSApp delegate];
  RMFFavoriteManager *favouriteManager = delegate.favoritesManager;
  if(favouriteManager == nil) {
    return; // no favourite Manager availabe
  }
  RMFRamdisk *ramdisk = [favouriteManager findFavouriteForDevicePath:devicePath];
  if(ramdisk == nil) {
    return; // no Favourite found for the mounted volume
  }
  if(ramdisk.backupMode != RMFNoBackup) {
    [self restoreRamdisk:ramdisk];
  }
}

- (void)backupIntervallChanged:(NSUInteger)interval {
  NSTimeInterval timeInterval = interval;
  [self disableTimer];
  self.backupTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(performBackup) userInfo:nil repeats:YES];
}

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
    interval = [self.backupTimer timeInterval];
    [self.backupTimer invalidate];
    self.backupTimer = nil;
  }
  [self backupIntervallChanged:interval];
}

@end

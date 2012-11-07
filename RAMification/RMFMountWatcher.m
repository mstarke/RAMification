//
//  RMFMountWatcher.m
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFMountWatcher.h"

#import "RMFAppDelegate.h"
#import "RMFFavouritesManager.h"
#import "RMFRamdisk.h"
#import "RMFChangedMountedFavouritesController.h"

#import <DiskArbitration/DiskArbitration.h>

NSString *const RMFDidMountRamdiskNotification = @"RMFDidMountRamdiskNotification";
NSString *const RMFDidUnmountRamdiskNotification = @"RMFDidUnmountRamdiskNotification";
NSString *const RMFDidRenameRamdiskNotification = @"RMFDidRenameRamdiskNotification";
NSString *const kRMFRamdiskKey = @"RMFRamdiskKey";
NSString *const kRMFOldRamdiskLabelKey = @"RMFOldRamdiskLabelKey";

@interface RMFMountWatcher ()

@property (retain) RMFChangedMountedFavouritesController *changedFavouritesController;

- (void)_didMountVolume:(NSNotification *)notification;
- (void)_didUnmountVolume:(NSNotification *)notification;
- (void)_didRenameVolume:(NSNotification *)notification;
- (void)_prepareMountedRamdisk:(RMFRamdisk *)ramdisk volumeURL:(NSURL *)volumeURL wasMountedAtStartup:(BOOL)wasMounted;
- (void)_presentChangedRamdisks:(NSArray *)ramdisks;

@end

@implementation RMFMountWatcher

+ (NSString *)bsdDeviceForVolumeAtURL:(NSURL *)volumeURL {
  // Create DA session and schedule it with run loop
  DASessionRef session = DASessionCreate(kCFAllocatorDefault);
  DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  // Get the disk for the path of the renamed volume
  DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, (CFURLRef)volumeURL);
  NSString *bsdDevice = [NSString stringWithUTF8String:DADiskGetBSDName(disk)];
  // Unschedule our session and clean up
  DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  CFRelease(disk);
  CFRelease(session);
  
  return bsdDevice;
}

- (id)init {
  self = [super init];
  if (self) {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *center = [workspace notificationCenter];
    // Register ourselves for mount/unmount events to easly update favourite mount status
    [center addObserver:self selector:@selector(_didMountVolume:) name:NSWorkspaceDidMountNotification object:nil];
    [center addObserver:self selector:@selector(_didUnmountVolume:) name:NSWorkspaceDidUnmountNotification object:nil];
    [center addObserver:self selector:@selector(_didRenameVolume:) name:NSWorkspaceDidRenameVolumeNotification object:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSNotificationCenter *center = [workspace notificationCenter];
  [center removeObserver:self];
  
  [super dealloc];
}

- (void)searchForMountedFavourites {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *mountedVolumeUrls = [fileManager mountedVolumeURLsIncludingResourceValuesForKeys:@[ NSURLVolumeNameKey, NSURLVolumeTotalCapacityKey, NSURLVolumeIsRemovableKey ] options:0];
  NSMutableArray *ramdiskWithChangedLabel = [NSMutableArray arrayWithCapacity:[mountedVolumeUrls count]];
  for( NSURL *volumeURL in mountedVolumeUrls) {
    BOOL hasValue = YES;
    NSString *name;
    NSNumber *capacity;
    NSNumber *isRemovable;
    hasValue &= [volumeURL getResourceValue:&name forKey:NSURLVolumeNameKey error:nil];
    hasValue &= [volumeURL getResourceValue:&capacity forKey:NSURLVolumeTotalCapacityKey error:nil];
    hasValue &= [volumeURL getResourceValue:&isRemovable forKey:NSURLVolumeIsRemovableKey error:nil];
    
    if(!hasValue) {
      continue; // No information. Skipp
    }
    
    if( [RMFRamdisk volumeIsRamdiskAtURL:volumeURL] ) {
      NSLog(@"Found already possible mounted favourite: %@. Trying to match up!", name);
      // find uuid by reading file
      BOOL foundUUID = NO;
      NSString *uuid = [RMFRamdisk uuidOfRamdiskAtAURL:volumeURL success:&foundUUID];
      
      if(foundUUID) {
        RMFRamdisk *ramdisk = [[RMFFavouritesManager sharedManager] findFavouriteByUUID:uuid];
        if(nil != ramdisk) {
          NSString *mountedLabel = [volumeURL lastPathComponent];
          if(NO == [ramdisk.label isEqualToString:mountedLabel]) {
            [ramdiskWithChangedLabel addObject:ramdisk];
          }
          [self _prepareMountedRamdisk:ramdisk volumeURL:volumeURL wasMountedAtStartup:YES];
        }
      }
    }
  }
  if([ramdiskWithChangedLabel count] != 0) {
    [self _presentChangedRamdisks:ramdiskWithChangedLabel];
  }
}

- (void)_didMountVolume:(NSNotification *)notification {
  NSString *volumeName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  NSURL *volumeURL = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  NSString *volumePath = [volumeURL path];
  
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  NSString *bsdDevice = [RMFMountWatcher bsdDeviceForVolumeAtURL:volumeURL];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteWithBsdDevice:bsdDevice];
  
  NSLog(@"%@: Device %@ got mounted at Path %@", self, bsdDevice, volumePath);
  if(ramdisk == nil || NO == [ramdisk.label isEqualToString:volumeName]) {
    NSLog(@"%@: No Ramdisk, ignoring!", self);
    return; // No known favourite was mounted, ignore
  }
  [self _prepareMountedRamdisk:ramdisk volumeURL:volumeURL wasMountedAtStartup:NO];
}

- (void)_didUnmountVolume:(NSNotification *)notification {
  NSURL *deviceUrl = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteWithVolumeURL:deviceUrl];
  NSLog(@"%@: Device %@ unmounted", self, deviceUrl);
  if( ramdisk == nil ) {
    NSLog(@"%@: No Ramdisk, ignoring", self);
    return; // No known favourite was unmounted, ignore
  }
  if(NO == ramdisk.isMounted) {
    NSLog(@"%@: Ramdisk %@ wasn't mounted", self, ramdisk.label);
    return; // RAM disk was not mounted
  }
  
  ramdisk.bsdDevice = nil;
  ramdisk.isMounted = NO;
  
  NSDictionary *userInfo = @{ kRMFRamdiskKey : ramdisk };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidUnmountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@: %@ was unmounted!", self, ramdisk);
}

- (void)_didRenameVolume:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSURL *newURL = [userInfo objectForKey:NSWorkspaceVolumeURLKey];
  NSString *newName =[userInfo objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  NSURL *oldURL = [userInfo objectForKey:NSWorkspaceVolumeOldURLKey];
  NSString *oldName = [userInfo objectForKey:NSWorkspaceVolumeOldLocalizedNameKey];
  
  NSLog(@"%@: Volume %@ got renamed to %@", self, oldName, newName);
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  
  RMFRamdisk *renamedDisk = [favouritesManager findFavouriteWithVolumeURL:oldURL];
  if(renamedDisk != nil) {
    NSDictionary *userInfo = @{ kRMFRamdiskKey : renamedDisk, kRMFOldRamdiskLabelKey : oldName };
    renamedDisk.label = newName;
    renamedDisk.volumeURL = newURL;
    [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidRenameRamdiskNotification object:self userInfo:userInfo];
  }
}

- (void)_prepareMountedRamdisk:(RMFRamdisk *)ramdisk volumeURL:(NSURL *)volumeURL wasMountedAtStartup:(BOOL)wasMounted {
  ramdisk.volumeURL = volumeURL;
  ramdisk.isMounted = YES;
  [ramdisk updateFinderLabel];
  [ramdisk prepareContent];

  // test for volume lable missmatch?
  
  // Post notification to notification center only if we did mount the ramdisk ourselfs
  if(NO == wasMounted) {
    NSUserNotificationCenter *notificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *userNotification = [[[NSUserNotification alloc] init] autorelease];
    userNotification.title = NSLocalizedString(@"NOTIFICATION_RAMDISK_CREATED", @"Ramdisk was created successfully");
    userNotification.subtitle = ramdisk.label;
    userNotification.deliveryDate = [NSDate date];
    
    [notificationCenter scheduleNotification:userNotification];
  }
  
  NSDictionary *userInfo = @{ kRMFRamdiskKey : ramdisk };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidMountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@: %@ was mounted!", self, ramdisk);
}

- (void)_presentChangedRamdisks:(NSArray *)ramdisks {
  // show dialog with changed ramdisks
  _changedFavouritesController =  [[RMFChangedMountedFavouritesController alloc] init];
  [_changedFavouritesController setChangedFavourites:ramdisks];
  [_changedFavouritesController showWindow:[_changedFavouritesController window]];
}

@end

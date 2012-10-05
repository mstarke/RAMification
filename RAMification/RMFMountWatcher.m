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

#import <DiskArbitration/DiskArbitration.h>

NSString * const RMFDidMountRamdiskNotification = @"RMFDidMountRamdiskNotification";
NSString * const RMFDidUnmountRamdiskNotification = @"RMFDidUnmountRamdiskNotification";
NSString * const RMFDidRenameRamdiskNotification = @"RMFDidRenameRamdiskNotification";
NSString * const kRMFRamdiskKey = @"RMFRamdiskKey";
NSString * const kRMFOldRamdiskLabelKey = @"RMFOldRamdiskLabelKey";

@interface RMFMountWatcher ()

- (void) didMountVolume:(NSNotification *)notification;
- (void) didUnmountVolume:(NSNotification *)notification;
- (void) didRenameVolume:(NSNotification *)notification;

@end

@implementation RMFMountWatcher

- (id)init {
  self = [super init];
  if (self) {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *center = [workspace notificationCenter];
    // Register ourselves for mount/unmount events to easly update favourite mount status
    [center addObserver:self selector:@selector(didMountVolume:) name:NSWorkspaceDidMountNotification object:nil];
    [center addObserver:self selector:@selector(didUnmountVolume:) name:NSWorkspaceDidUnmountNotification object:nil];
    [center addObserver:self selector:@selector(didRenameVolume:) name:NSWorkspaceDidRenameVolumeNotification object:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)didMountVolume:(NSNotification *)notification {
  NSString *volumeName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  NSURL *volumeUrl = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  NSString *volumePath = [volumeUrl path];
   
  // Create DA session and schedule it with run loop
  DASessionRef session = DASessionCreate(kCFAllocatorDefault);
  DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  // Get the disk for the path of the renamed volume
  DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, (CFURLRef)volumeUrl);
  NSString *bsdDevice = [NSString stringWithUTF8String:DADiskGetBSDName(disk)];
  // Unschedule our session and clean up
  DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  CFRelease(disk);
  CFRelease(session);
  
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteWithBsdDevice:bsdDevice];

  NSLog(@"%@: Device %@ got mounted at Path %@", self, bsdDevice, volumePath);
  if(ramdisk == nil || NO == [ramdisk.label isEqualToString:volumeName]) {
    NSLog(@"%@: No Ramdisk, ignoring!", self);
    return; // No known favourite was mounted, ignore
  }
  ramdisk.volumePath = volumePath;
  
  NSDictionary *userInfo = @{ kRMFRamdiskKey : ramdisk };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidMountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@: %@ was mounted!", self, ramdisk);
}

- (void)didUnmountVolume:(NSNotification *)notification {
  NSURL *deviceUrl = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  NSString *devicePath = [deviceUrl path];
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteWithVolumePath:devicePath];
  NSLog(@"%@: Device %@ unmounted", self, devicePath);
  if( ramdisk == nil ) {
    NSLog(@"%@: No Ramdisk, ignoring", self);
    return; // No known favourite was unmounted, ignore
  }
  if(NO == ramdisk.isMounted) {
    NSLog(@"%@: Ramdisk %@ wasn't mounted", self, ramdisk.label);
    return; // RAM disk was not mounted
  }
 
  ramdisk.bsdDevice = nil;
  
  NSDictionary *userInfo = @{ kRMFRamdiskKey : ramdisk };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidUnmountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@: %@ was unmounted!", self, ramdisk);
}

- (void)didRenameVolume:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSURL *newPath = [userInfo objectForKey:NSWorkspaceVolumeURLKey];
  NSString *newName =[userInfo objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  NSURL *oldPath = [userInfo objectForKey:NSWorkspaceVolumeOldURLKey];
  NSString *oldName = [userInfo objectForKey:NSWorkspaceVolumeOldLocalizedNameKey];
  
  NSLog(@"%@: Volume %@ got renamed to %@", self, oldName, newName);
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  
  RMFRamdisk *renamedDisk = [favouritesManager findFavouriteWithVolumePath:[oldPath path]];
  if(renamedDisk != nil) {
    NSDictionary *userInfo = @{ kRMFRamdiskKey : renamedDisk, kRMFOldRamdiskLabelKey : oldName };
    renamedDisk.label = newName;
    renamedDisk.volumePath = [newPath path];
    [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidRenameRamdiskNotification object:self userInfo:userInfo];
  }
}

@end

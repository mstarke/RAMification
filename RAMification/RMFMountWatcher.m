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
NSString * const RMFRamdiskKey = @"RMFRamdiskKey";
NSString * const RMFOldRamdiskLabelKey = @"RMFOldRamdiskLabelKey";

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
  }
  return self;
}

- (void)didMountVolume:(NSNotification *)notification {
  NSString *deviceName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  NSString *devicePath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteForDevicePath:devicePath];
  if(ramdisk == nil || ramdisk.label != deviceName) {
    return; // No known favourite was mounted, ignore
  }
  ramdisk.isMounted = YES;
  NSDictionary *userInfo = @{ RMFRamdiskKey : ramdisk };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidMountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@ was mounted!", ramdisk);
}

- (void)didUnmountVolume:(NSNotification *)notification {
  NSString *devicePath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteForDevicePath:devicePath];
  if( ramdisk == nil ) {
    return; // No known favourite was unmounted, ignore
  }
  ramdisk.isMounted = NO;
  ramdisk.devicePath = nil;
  NSDictionary *userInfo = @{ RMFRamdiskKey : ramdisk };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidUnmountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@ was unmounted!", ramdisk);
}

- (void)didRenameVolume:(NSNotification *)notification {
  NSURL *newPath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  NSString *newName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  // Create DA session and schedule it with run loop
  DASessionRef session = DASessionCreate(kCFAllocatorDefault);
  DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  // Get the disk for the path of the renamed volume
  DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, (CFURLRef)newPath);
  NSString *devicePath = [NSString stringWithUTF8String:DADiskGetBSDName(disk)];
  // Unschedule our session and clean up
  DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  CFRelease(disk);
  CFRelease(session);
  
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *renamedDisk = [favouritesManager findFavouriteForDevicePath:devicePath];
  
  if(renamedDisk != nil) {
    NSDictionary *userInfo = @{ RMFRamdiskKey : renamedDisk, RMFOldRamdiskLabelKey : renamedDisk.label };
    renamedDisk.label = newName;
    renamedDisk.devicePath = devicePath;
    [[NSNotificationCenter defaultCenter] postNotificationName:RMFDidRenameRamdiskNotification object:self userInfo:userInfo];
  }
}

@end

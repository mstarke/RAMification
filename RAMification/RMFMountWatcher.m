//
//  RMFMountWatcher.m
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFMountWatcher.h"

#import "RMFAppDelegate.h"
#import "RMFFavoriteManager.h"
#import "RMFRamdisk.h"

#import <DiskArbitration/DiskArbitration.h>

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
  RMFAppDelegate *delegate = [NSApp delegate];
  RMFRamdisk *ramdisk = [delegate.favoritesManager findFavouriteForDevicePath:devicePath];
  if(ramdisk == nil || ramdisk.label != deviceName) {
    return; // No known favourite was mounted, ignore
  }
  ramdisk.isMounted = YES;
  NSLog(@"%@ was mounted!", ramdisk);
}

- (void)didUnmountVolume:(NSNotification *)notification {
  NSString *devicePath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  RMFAppDelegate *delegate = [NSApp delegate];
  RMFRamdisk *ramdisk = [delegate.favoritesManager findFavouriteForDevicePath:devicePath];
  if( ramdisk == nil ) {
    return; // No known favourite was unmounted, ignore
  }
  ramdisk.isMounted = NO;
  NSLog(@"%@ was unmounted!", ramdisk);
}

- (void)didRenameVolume:(NSNotification *)notification {
  NSString *oldName = [[notification userInfo] objectForKey:NSWorkspaceVolumeOldLocalizedNameKey];
  //NSString *newName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  NSURL *newPath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  RMFAppDelegate *delegate = [NSApp delegate];
  RMFFavoriteManager *favouriteManager = delegate.favoritesManager;
  RMFRamdisk *renamedDisk = [favouriteManager findFavouriteForName:oldName];
  // Might work better in a differen fashion?
  if(renamedDisk.isMounted) {
    DASessionRef renameSession = DASessionCreate(CFAllocatorGetDefault());
    DASessionScheduleWithRunLoop(renameSession, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    DADiskRef disk = DADiskCreateFromVolumePath(CFAllocatorGetDefault(), renameSession, (CFURLRef)newPath);
    DADiskRename(disk, (CFStringRef)oldName, NULL, NULL, NULL);
    CFRelease(disk);
    CFRelease(renameSession);
  }
}

@end

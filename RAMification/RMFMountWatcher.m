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

@implementation RMFMountWatcher

- (id)init {
  self = [super init];
  if (self) {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *center = [workspace notificationCenter];
    /*
     Register ourselves for mount/unmount events to easly update favourite mount status
     */
    [center addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
    [center addObserver:self selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
  }
  return self;
}

- (void)volumeDidMount:(NSNotification *)notification {
  //NSString *deviceName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  NSString *devicePath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  RMFAppDelegate *delegate = [NSApp delegate];
  RMFRamdisk *ramdisk = [delegate.favoritesManager findFavouriteForDevicePath:devicePath];
  if( ramdisk == nil ) {
    return; // No known favourite was mounted, ignore
  }
  ramdisk.isMounted = YES;
  NSLog(@"%@ was mounted!", ramdisk);
}

- (void)volumeDidUnmount:(NSNotification *)notification {
  NSString *devicePath = [[notification userInfo] objectForKey:NSWorkspaceVolumeURLKey];
  RMFAppDelegate *delegate = [NSApp delegate];
  RMFRamdisk *ramdisk = [delegate.favoritesManager findFavouriteForDevicePath:devicePath];
  if( ramdisk == nil ) {
    return; // No known favourite was unmounted, ignore
  }
  ramdisk.isMounted = NO;
  NSLog(@"%@ was unmounted!", ramdisk);
}

@end

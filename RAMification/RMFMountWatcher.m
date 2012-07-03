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

@implementation RMFMountWatcher

- (id)init
{
  self = [super init];
  if (self)
  {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *center = [workspace notificationCenter];
    [center addObserver:self selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
    [center addObserver:self selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
    [center addObserver:self selector:@selector(volumeWillUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];    
  }
  return self;
}

- (void)volumeDidMount:(NSNotification *)notification
{
  NSString *deviceName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  RMFAppDelegate *delegate = [NSApp delegate];
  [delegate.favoritesManager updateFavourites];
}

- (void)volumeWillUnmount:(NSNotification *)notification
{

}

- (void)volumeDidUnmount:(NSNotification *)notification
{
  NSString *deviceName = [[notification userInfo] objectForKey:NSWorkspaceVolumeLocalizedNameKey];
  RMFAppDelegate *delegate = [NSApp delegate];
  [delegate.favoritesManager updateFavourites];
}

@end

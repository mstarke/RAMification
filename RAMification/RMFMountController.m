//
//  RMFMountController.m
//  RAMification
//
//  Created by Michael Starke on 05.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFMountController.h"

#import "RMFAppDelegate.h"
#import "RMFRamdisk.h"
#import "RMFFavoriteManager.h"
#import "RMFCreateRamDiskOperation.h"
#import "NSString+RMFVolumeTools.h"

@interface RMFMountController ()

@property (retain) NSOperationQueue *queue;

- (void) mount:(RMFRamdisk *)ramdisk;
- (void) unmount:(RMFRamdisk *)ramdisk;

@end

@implementation RMFMountController

@synthesize queue = _queue;

- (id)init
{
  self = [super init];
  if (self) {
    _queue = [[NSOperationQueue alloc] init];
  }
  return self;
}

- (void)dealloc
{
  self.queue = nil;
  [super dealloc];
}

- (void) mount:(RMFRamdisk *)ramdisk
{
  RMFCreateRamDiskOperation *mountOperation = [[RMFCreateRamDiskOperation alloc] initWithRamdisk:ramdisk];
  [self.queue cancelAllOperations];
  [self.queue addOperation:mountOperation];
  [mountOperation release];
}

- (void) unmount:(RMFRamdisk *)ramdisk
{
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[ramdisk.label volumePath]];
}

- (BOOL) toggleMounted:(RMFRamdisk *)ramdisk
{
  return NO;
}

- (void) volumeAtPath:(NSString *)path wasMounted:(BOOL)mounted
{
  RMFFavoriteManager *favouriteManager = ((RMFAppDelegate *)[NSApp delegate]).favoritesManager;
  RMFRamdisk *ramdisk = [favouriteManager findFavouriteForDevicePath:path];
  if(ramdisk != nil)
  {
    ramdisk.isMounted = mounted;
  }
}


@end

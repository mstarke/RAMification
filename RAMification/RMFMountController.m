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
#import "RMFFavouritesManager.h"
#import "RMFCreateRamDiskOperation.h"
#import "NSString+RMFVolumeTools.h"

static RMFMountController *sharedSingleton;

@interface RMFMountController ()

@property (retain) NSOperationQueue *queue;

@end

@implementation RMFMountController

+ (void)initialize {
  static BOOL initialized = NO;
  if(!initialized) {
    initialized = YES;
    sharedSingleton = [[RMFMountController alloc] init];
  }
}

+ (RMFMountController *)sharedController {
  return sharedSingleton;
}

- (id)init {
  self = [super init];
  if (self) {
    _queue = [[NSOperationQueue alloc] init];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  self.queue = nil;
  [super dealloc];
}

- (void) mount:(RMFRamdisk *)ramdisk {
  if(ramdisk.isMounted) {
    return; // already mounted
  }
  RMFCreateRamDiskOperation *mountOperation = [[RMFCreateRamDiskOperation alloc] initWithRamdisk:ramdisk];
  [self.queue cancelAllOperations];
  [self.queue addOperation:mountOperation];
  [mountOperation release];
}

- (void) unmount:(RMFRamdisk *)ramdisk {
  if(NO == ramdisk.isMounted) {
    return; // Already unmounted
  }
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[ramdisk.label volumePath]];
}

- (BOOL) toggleMounted:(RMFRamdisk *)ramdisk {
  
  if (ramdisk.isMounted) {
    [self unmount:ramdisk];
    return YES; // we did mount the ramdisk
  }
  else {
    [self mount:ramdisk];
    return NO; // we did unmount the ramdisk
  }
}

- (void) volumeAtPath:(NSString *)path wasMounted:(BOOL)mounted {
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *ramdisk = [favouriteManager findFavouriteForDevicePath:path];
  if(ramdisk != nil) {
    ramdisk.isMounted = mounted;
  }
}
@end

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

static RMFMountController *_sharedSingleton;

@interface RMFMountController ()

@property (retain) NSOperationQueue *queue;

@end

@implementation RMFMountController

+ (void)initialize {
  static BOOL initialized = NO;
  if(!initialized) {
    initialized = YES;
    _sharedSingleton = [[RMFMountController alloc] init];
  }
}

+ (RMFMountController *)sharedController {
  return _sharedSingleton;
}

+ (BOOL)isMemoryAvailableForRamdisk:(RMFRamdisk *)ramdisk {
  unsigned long long systemMemory = [[NSProcessInfo processInfo] physicalMemory];
  return (ramdisk.size <= systemMemory);
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

- (void)mount:(RMFRamdisk *)ramdisk autoskipCriticalSize:(BOOL)autoskip {
  if(ramdisk.isMounted) {
    return; // already mounted
  }
  if(NO == [RMFMountController isMemoryAvailableForRamdisk:ramdisk]) {
    if(autoskip) {
      return; // no user feedback so we got the save way and skipp
    }
    
    NSString *infoTextTemplate = NSLocalizedString(@"ALERT_RAMDISK_SIZE_WARNING_INFO_TEXT", @"Additinal info to dispaly on trying to mount too large RAM disk %1 System size %2 RAM disk size");
    NSString *availableRam = [NSByteCountFormatter stringFromByteCount:[[NSProcessInfo processInfo] physicalMemory] countStyle:NSByteCountFormatterCountStyleBinary];
    NSString *ramdisksize = [NSByteCountFormatter stringFromByteCount:ramdisk.size countStyle:NSByteCountFormatterCountStyleBinary];
    NSString *infoText = [NSString stringWithFormat:infoTextTemplate, availableRam, ramdisksize];
    
    NSAlert *sizeAlert = [[NSAlert alloc] init];
    //[sizeAlert setAlertStyle:NSCriticalAlertStyle];
    [sizeAlert addButtonWithTitle:NSLocalizedString(@"ALERT_RAMDISK_SIZE_TOO_BIG_NOMOUNT", @"Do not mount RAM disk with low memory")];
    [sizeAlert addButtonWithTitle:NSLocalizedString(@"ALERT_RAMDISK_SIZE_TOO_BIG_MOUNT", @"Mount RAM disk dispite low memory")];
    [sizeAlert setMessageText:NSLocalizedString(@"ALERT_RAMDISK_SIZE_WARNING_TITLE", @"Titel to dispaly on trying to mount too large RAM disk")];
    [sizeAlert setInformativeText:infoText];
    
    if( [sizeAlert runModal] == NSAlertFirstButtonReturn ) {
      return; // user canceld operation
    }
  }
  
  RMFCreateRamDiskOperation *mountOperation = [[RMFCreateRamDiskOperation alloc] initWithRamdisk:ramdisk];
  [self.queue cancelAllOperations];
  [self.queue addOperation:mountOperation];
  [mountOperation release];
}

- (void)unmount:(RMFRamdisk *)ramdisk {
  if(NO == ramdisk.isMounted) {
    return; // Already unmounted
  }
  NSError *error = nil;
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtURL:ramdisk.volumeURL error:&error];
  if(nil != error) {
    NSLog(@"Could not unmount Ramdisk %@ mounted at %@. %@", ramdisk.label, ramdisk.volumeURL, [error localizedDescription] );
  }
}

- (BOOL)toggleMounted:(RMFRamdisk *)ramdisk {
  
  if (ramdisk.isMounted) {
    [self unmount:ramdisk];
    return YES; // we did mount the ramdisk
  }
  else {
    [self mount:ramdisk autoskipCriticalSize:NO];
    return NO; // we did unmount the ramdisk
  }
}

- (void)renameVolume:(RMFRamdisk *)ramdisk mountedAs:(NSString *)currentName {
  
}

@end

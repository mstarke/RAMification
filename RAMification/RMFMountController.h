//
//  RMFMountController.h
//  RAMification
//
//  Created by Michael Starke on 05.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFRamdisk.h"
/*
 The Mount Controller is responsible for creating the mount/unomunt operations and should be used to mount/unmount a Ramdisk
 */
@interface RMFMountController : NSObject

+ (RMFMountController *)sharedController;

- (BOOL)toggleMounted:(RMFRamdisk *)ramdisk;
- (void)mount:(RMFRamdisk *)ramdisk;
- (void)unmount:(RMFRamdisk *)ramdisk;
- (void)renameVolume:(RMFRamdisk *)ramdisk mountedAs:(NSString *)currentName;

@end

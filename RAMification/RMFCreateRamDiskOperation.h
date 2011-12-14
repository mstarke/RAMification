//
//  NSCreateRamDiskOperation.h
//  RAMification
//
//  Created by Michael Starke on 28.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFRamdisk.h"

@interface RMFCreateRamDiskOperation : NSOperation

@property (retain) RMFRamdisk* ramdisk;

- (id) initWithRamdisk:(RMFRamdisk *)ramdisk;

@end

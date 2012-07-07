//
//  NSCreateRamDiskOperation.h
//  RAMification
//
//  Created by Michael Starke on 28.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RMFRamdisk;

@interface RMFCreateRamDiskOperation : NSOperation

- (id) initWithRamdisk:(RMFRamdisk *)ramdisk;

@end

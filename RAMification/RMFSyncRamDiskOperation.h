//
//  RMFSyncRamDiskOperation.h
//  RAMification
//
//  Created by Michael Starke on 08.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RMFRamdisk;

/* Wraps an rsync taks to synchronize a ramdisk */
@interface RMFSyncRamDiskOperation : NSOperation

- (id)initWithRamdisk:(RMFRamdisk *)ramdisk;

@end

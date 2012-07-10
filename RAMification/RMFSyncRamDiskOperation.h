//
//  RMFSyncRamDiskOperation.h
//  RAMification
//
//  Created by Michael Starke on 08.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RMFRamdisk;

/* Synchronsation mode for the backup */
typedef enum RMFSyncModeType {
  RMFSyncModeNone, // Synchronize nothing
  RMFSyncModeRestore, // Just restore the ramdisk from disk
  RMFSyncModeBackup, // Just backup the ramdisk to disk
} RMFSyncMode;

/* Wraps an rsync taks to synchronize a ramdisk */
@interface RMFSyncRamDiskOperation : NSOperation

@property (retain,readonly) RMFRamdisk *ramdisk;

/* Creates a synchronization operation for the given ramdisk with the given mode */
- (id)initWithRamdisk:(RMFRamdisk *)ramdisk mode:(RMFSyncMode)syncMode;

@end

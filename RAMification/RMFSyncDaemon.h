//
//  RMFSyncDaemon.h
//  RAMification
//
//  Created by Michael Starke on 17.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

@class RMFRamdisk;

/*
 This class wraps rsync to synchronize changes of a ramdisk to disk
 It flushes any non-backed up changes on unmounting and by this means minimizes data loss
 */
@interface RMFSyncDaemon : NSObject

// Register the given ramdisk for backups.
- (void)enableBackupForRamdisk: (RMFRamdisk *)ramdisk;
// Unregesiter the given ramdisk to stop backups
- (void)disableBackupForRamdisk:(RMFRamdisk *)ramdisk;

@end

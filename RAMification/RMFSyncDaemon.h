//
//  RMFSyncDaemon.h
//  RAMification
//
//  Created by Michael Starke on 17.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RMFRamdisk;

/*
 This class wraps rsync to synchronize changes of a ramdisk to disk
 It flushes any non-backed up changes on unmounting and by this means minimizes data loss
 */
@interface RMFSyncDaemon : NSObject

@end

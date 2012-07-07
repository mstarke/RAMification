//
//  RMFSyncRamDiskOperation.m
//  RAMification
//
//  Created by Michael Starke on 08.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSyncRamDiskOperation.h"

#import "RMFRamdisk.h"

@interface RMFSyncRamDiskOperation ()
@property (retain) RMFRamdisk *ramdisk;
@end

@implementation RMFSyncRamDiskOperation

@synthesize ramdisk = _ramdisk;


- (id)init {
  RMFRamdisk *ramdisk = [[RMFRamdisk alloc] init];
  self = [self initWithRamdisk:ramdisk];
  [ramdisk release];
  return self;
}

- (id)initWithRamdisk:(RMFRamdisk *)ramdisk {
  self = [super init];
  if (self) {
    self.ramdisk = ramdisk;
  }
  return self;
}

- (void)main {
  if( self.isCancelled ) {
    NSLog(@"Synchronization got canceled!");
    return;
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSTask *rsync = [[NSTask alloc] init];
  [rsync setLaunchPath:@"/usr/bin/rsync"];
   
  
  [pool drain];
}

@end

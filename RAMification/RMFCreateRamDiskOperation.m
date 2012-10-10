//
//  NSCreateRamDiskOperation.m
//  RAMification
//
//  Created by Michael Starke on 28.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFCreateRamDiskOperation.h"

#import "RMFAppDelegate.h"
#import "RMFRamdisk.h"
#import "NSString+RMFVolumeTools.h"

@interface RMFCreateRamDiskOperation ()
  @property (retain) RMFRamdisk* ramdisk;
@end

@implementation RMFCreateRamDiskOperation

- (id) initWithRamdisk:(RMFRamdisk *)ramdisk {
  self = [super init];
  if (self) {
    self.ramdisk = ramdisk;
  }
  return self;
}

- (id) init {
  RMFRamdisk* ramdisk= [[RMFRamdisk alloc] init];
  self = [self initWithRamdisk:ramdisk];
  [ramdisk release];
  return self;
}

- (void) main {  
  // stop if we are cancelled or are a already mounted volume
  if([self isCancelled]) {
    NSLog(@"We got canceled!");
    return;
  }
  if([self.ramdisk.label isUsedAsVolumeName]) {
    NSLog(@"The Volume is already present!");
    return;
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // wrap the creation method in a block to call it asynchrounous.
  
  NSPipe *output = [NSPipe pipe];  
 
  // create the device
  // hdiutil attach -nomount ram://MB*2048
  
  // create the string for the desired ramdisksize
  NSString *ramdisksize = [NSString stringWithFormat:@"ram://%ld", self.ramdisk.size/512];
  
  // create the task and run it
  NSTask *createBlockDevice = [[NSTask alloc] init];
  [createBlockDevice setLaunchPath:@"/usr/bin/hdiutil"];
  [createBlockDevice setArguments:[NSArray arrayWithObjects:@"attach", @"-nomount", ramdisksize, nil]];
  [createBlockDevice setStandardOutput:output];
  [createBlockDevice launch];
  
  // retrieve the device name
  NSFileHandle *outputFileHandle = [output fileHandleForReading];
  NSString *deviceName = [[NSString alloc] initWithData:[outputFileHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
  NSString *strippedDeviceName = [deviceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  self.ramdisk.bsdDevice = [strippedDeviceName lastPathComponent];
  [deviceName release];
  [createBlockDevice release];
  
  // and format it
  // diskutil erasevolume HFS+ <NAME> <DEVICE>
  NSTask *formatDisk = [[NSTask alloc] init];
  [formatDisk setLaunchPath:@"/usr/sbin/diskutil"];
  [formatDisk setArguments:[NSArray arrayWithObjects:@"erasevolume", @"HFS+", self.ramdisk.label, strippedDeviceName, nil]];
  [formatDisk launch];
  [formatDisk release];
 
  [pool drain];
  // we could set the mountes state here or let the MountWatcher take care of it
  // self.ramdisk.isMounted = YES;
}

@end

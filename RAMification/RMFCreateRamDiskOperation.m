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
  @property (strong) RMFRamdisk* ramdisk;
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
  return self;
}

- (void) main {  
  // stop if we are cancelled or are a already mounted volume
  if([self isCancelled]) {
    NSLog(@"We got canceled!");
    return;
  }
  
  @autoreleasepool {
  // wrap the creation method in a block to call it asynchrounous.
  
    NSPipe *output = [NSPipe pipe];  
 
    // create the device
    // hdiutil attach -nomount ram://MB*2048
    
    // create the string for the desired ramdisksize
    NSString *ramdisksize = [NSString stringWithFormat:@"ram://%ld", self.ramdisk.size/512];
    
    // create the task and run it
    NSTask *createBlockDevice = [[NSTask alloc] init];
    [createBlockDevice setLaunchPath:@"/usr/bin/hdiutil"];
    [createBlockDevice setArguments:@[@"attach", @"-nomount", ramdisksize]];
    [createBlockDevice setStandardOutput:output];
    [createBlockDevice launch];
    
    // retrieve the device name
    NSFileHandle *outputFileHandle = [output fileHandleForReading];
    NSString *deviceName = [[NSString alloc] initWithData:[outputFileHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSString *strippedDeviceName = [deviceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.ramdisk.bsdDevice = [strippedDeviceName lastPathComponent];
    
    // and format it
    // diskutil erasevolume HFS+ <NAME> <DEVICE>
    NSTask *formatDisk = [[NSTask alloc] init];
    [formatDisk setLaunchPath:@"/usr/sbin/diskutil"];
    [formatDisk setArguments:@[@"erasevolume", @"HFS+", self.ramdisk.label, strippedDeviceName]];
    [formatDisk launch];
 
  }
  // we could set the mountes state here or let the MountWatcher take care of it
  // self.ramdisk.isMounted = YES;
}

@end

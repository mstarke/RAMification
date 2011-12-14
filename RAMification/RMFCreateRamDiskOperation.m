//
//  NSCreateRamDiskOperation.m
//  RAMification
//
//  Created by Michael Starke on 28.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFCreateRamDiskOperation.h"
#import "RMFAppDelegate.h"
#import "NSString+RMFVolumeTools.h"

@implementation RMFCreateRamDiskOperation

@synthesize ramdisk = _ramdisk;

- (id) initWithRamdisk:(RMFRamdisk *)ramdisk
{
  self = [super init];
  if (self)
  {
    self.ramdisk = ramdisk;
  }
  return self;
}

- (id) init
{
  RMFRamdisk* ramdisk= [[RMFRamdisk alloc] init];
  self = [self initWithRamdisk:ramdisk];
  [ramdisk release];
  return self;
}

- (void) main
{  
  // stop if we are cancelled or are a already mounted volume
  if([self isCancelled] || [self.ramdisk.label isUsedAsVolumeName])
  {  
    NSLog(@"We got canceld or the Volume is already present!");
    return;
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // wrap the creation method in a block to call it asynchrounous.
  
  NSPipe *output = [NSPipe pipe];  
  NSTask *createDisk = [[NSTask alloc] init];
  
  // create the device
  // hdiutil attach -nomount ram://MB*2048
  
  // create the string for the desired ramdisksize
  NSString *ramdisksize = [NSString stringWithFormat:@"ram://%d", self.ramdisk.size*2048];
  
  // create the task and run it
  [createDisk setLaunchPath:@"/usr/bin/hdiutil"];
  [createDisk setArguments:[NSArray arrayWithObjects:@"attach", @"-nomount", ramdisksize, nil]];
  [createDisk setStandardOutput:output];
  [createDisk launch];
  
  
  // retrieve the device name
  NSFileHandle *outputFileHandle = [output fileHandleForReading];
  NSString *deviceName = [[NSString alloc] initWithData:[outputFileHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
  NSString *strippedDeviceName = [deviceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  self.ramdisk.devicePath = deviceName;
  [deviceName release];
  [createDisk release];
  
  // and format it
  // diskutil erasevolume HFS+ <NAME> <DEVICE>
  createDisk = [[NSTask alloc] init];
  [createDisk setLaunchPath:@"/usr/sbin/diskutil"];
  [createDisk setArguments:[NSArray arrayWithObjects:@"erasevolume", @"HFS+", self.ramdisk.label, strippedDeviceName, nil]];
  [createDisk launch];
  [createDisk release];
  
  [pool drain];
  // we could set the mountes state here or let the MountWatcher take care of it
  // self.ramdisk.isMounted = YES;
}

@end

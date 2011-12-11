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

@synthesize preset = _preset;

- (id) initWithPreset:(RMFVolumePreset *)preset
{
  self = [super init];
  if (self)
  {
    self.preset = preset;
  }
  return self;
}

- (id) init
{
  RMFVolumePreset* preset = [[RMFVolumePreset alloc] init];
  self = [self initWithPreset:preset];
  [preset release];
  return self;
}

- (void) main
{  
  // stop if we are cancelled or are a already mounted volume
  if([self isCancelled] || [self.preset.volumeLabel isUsedAsVolumeName])
  {  
    return;
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // wrap the creation method in a block to call it asynchrounous.
  
  NSPipe *output = [NSPipe pipe];  
  NSTask *createDisk = [[NSTask alloc] init];
  
  // create the device
  // hdiutil attach -nomount ram://MB*2048
  
  // create the string for the desired ramdisksize
  NSString *ramdisksize = [NSString stringWithFormat:@"ram://%d", self.preset.diskSize*2048];
  
  // create the task and run it
  [createDisk setLaunchPath:@"/usr/bin/hdiutil"];
  [createDisk setArguments:[NSArray arrayWithObjects:@"attach", @"-nomount", ramdisksize, nil]];
  [createDisk setStandardOutput:output];
  [createDisk launch];
  
  
  // retrieve the device name
  NSFileHandle *outputFileHandle = [output fileHandleForReading];
  NSString *deviceName = [[NSString alloc] initWithData:[outputFileHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
  NSString *strippedDeviceName = [deviceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [deviceName release];
  [createDisk release];
  
  // and format it
  // diskutil erasevolume HFS+ <NAME> <DEVICE>
  createDisk = [[NSTask alloc] init];
  [createDisk setLaunchPath:@"/usr/sbin/diskutil"];
  [createDisk setArguments:[NSArray arrayWithObjects:@"erasevolume", @"HFS+", self.preset.volumeLabel, strippedDeviceName, nil]];
  [createDisk launch];
  [createDisk release];
  
  [pool drain];
  
  // if the Mount finished tell the application that this thing is mounted
  RMFAppDelegate *appDelegate = [NSApp delegate];
  NSLog(@"Adding %@ with device name %@", self.preset.volumeLabel, strippedDeviceName);
  [appDelegate.mountedVolumes setObject:self.preset.volumeLabel forKey:strippedDeviceName];
  
  //diskutil erasevolume HFS+ "ramdisk" `hdiutil attach -nomount ram://MB*2048`
}

@end

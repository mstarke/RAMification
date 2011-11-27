//
//  NSCreateRamDiskOperation.m
//  RAMification
//
//  Created by Michael Starke on 28.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFCreateRamDiskOperation.h"
@implementation RMFCreateRamDiskOperation

@synthesize size = _size;
@synthesize label = _label;

- (id) initWithSize:(NSUInteger)size andLabel:(NSString *)label
{
  self = [super init];
  if (self)
  {
    self.label = label;
    self.size = size;
  }
  return self;
}

- (void) main
{  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // wrap the creation method in a block to call it asynchrounous.
  
  //NSOperationQueue *operationQueeu = [NSOperationQueue ]
  NSPipe *output = [NSPipe pipe];  
  NSTask *createDisk = [[NSTask alloc] init];
  
  // create the device
  // hdiutil attach -nomount ram://MB*2048
  
  // create the string for the desired ramdisksize
  NSString *ramdisksize = [NSString stringWithFormat:@"ram://%d", self.size*2048];
  
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
  [createDisk setArguments:[NSArray arrayWithObjects:@"erasevolume", @"HFS+", self.label, strippedDeviceName, nil]];
  [createDisk launch];
  [createDisk release];
  
  [pool drain];
  
  //diskutil erasevolume HFS+ "ramdisk" `hdiutil attach -nomount ram://MB*2048`
}

@end

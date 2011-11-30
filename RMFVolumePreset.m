//
//  RMFPresets.m
//  RAMification
//
//  Created by Michael Starke on 27.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFVolumePreset.h"

@implementation RMFVolumePreset

@synthesize diskSize;
@synthesize volumeLabel;
@synthesize shouldAutoMount;

+ (NSUInteger) defaultDiskSize
{
  return 4096;
}

+ (NSString*) defaultVolumeLabel
{
  [[NSUserDefaults standardUserDefaults] valueForKey:@""];
  return @"RAMdisk";
}

@end

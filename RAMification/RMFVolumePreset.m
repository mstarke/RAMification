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

+ (RMFVolumePreset *) VolumePresetWithLable:(NSString *)aLabel andSize:(NSUInteger)aSize shouldAutoMount:(BOOL)mount
{
  return [[[RMFVolumePreset alloc] initWithLabel:aLabel andSize:aSize] autorelease];
}

+ (RMFVolumePreset *) VolumePreset
{
  return [[[RMFVolumePreset alloc] init] autorelease];
}

+ (NSUInteger) defaultDiskSize
{
  return 4096;
}

+ (NSString *) defaultVolumeLabel
{
  [[NSUserDefaults standardUserDefaults] valueForKey:@""];
  return @"RAMdisk";
}

- (id)init
  {
    return [self initWithLabel:[RMFVolumePreset defaultVolumeLabel] andSize:[RMFVolumePreset defaultDiskSize]];
  }

- (id)initWithLabel:(NSString *)aLable andSize:(NSUInteger)aSize {
  self = [super init];
  if (self)
  {
    self.diskSize = aSize;
    self.volumeLabel = aLable;
    self.shouldAutoMount = false;
  }
  return self;
}

@end

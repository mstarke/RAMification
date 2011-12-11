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
  return [[[RMFVolumePreset alloc] initWithLabel:aLabel andSize:aSize shouldMount:mount] autorelease];
}

+ (RMFVolumePreset *) VolumePreset
{
  return [[[RMFVolumePreset alloc] init] autorelease];
}

+ (RMFVolumePreset *)VolumePresetWithContentOfDict:(NSDictionary *)dict
{
  NSArray *keys = [dict allKeys];
  RMFVolumePreset *preset = nil;
  if([keys containsObject:@"lable"] && [keys containsObject:@"size"] && [keys containsObject:@"automount"])
  {
    preset = [[RMFVolumePreset alloc] init];
    preset.volumeLabel = [dict objectForKey:@"label"];
    preset.diskSize = [[dict objectForKey:@"size"] unsignedIntegerValue];
    preset.shouldAutoMount = [[dict objectForKey:@"automount"] boolValue];
  }
  return [preset autorelease];
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
    return [self initWithLabel:[RMFVolumePreset defaultVolumeLabel] andSize:[RMFVolumePreset defaultDiskSize] shouldMount:NO];
  }

- (id)initWithLabel:(NSString *)aLable andSize:(NSUInteger)aSize shouldMount:(BOOL)mount{
  self = [super init];
  if (self)
  {
    self.diskSize = aSize;
    if(aLable != nil)
    {
      self.volumeLabel = aLable;
    }
    else
    {
      self.volumeLabel = [RMFVolumePreset defaultVolumeLabel];
    } 
    self.shouldAutoMount = mount;
  }
  return self;
}

- (NSDictionary *)convertToDictionary
{
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.volumeLabel, @"label",
                                                                  [NSNumber numberWithUnsignedInteger: self.diskSize], @"size",
                                                                  [NSNumber numberWithBool:self.shouldAutoMount],@"automount",
                                                                  nil];
  return dict;
}

- (BOOL)isEqual:(id)object
{
  BOOL isEqual = NO;
  
  if([object isMemberOfClass:[RMFVolumePreset class]])
  {
    RMFVolumePreset* other = (RMFVolumePreset*)object;
    isEqual = (self.volumeLabel == other.volumeLabel);
  }
  return isEqual;
}

@end

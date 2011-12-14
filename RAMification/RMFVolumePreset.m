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
@synthesize isMounted;

+ (RMFVolumePreset *) VolumePresetWithLable:(NSString *)aLabel andSize:(NSUInteger)aSize shouldAutoMount:(BOOL)mount
{
  return [[[RMFVolumePreset alloc] initWithLabel:aLabel andSize:aSize shouldMount:mount] autorelease];
}

+ (RMFVolumePreset *) VolumePreset
{
  return [[[RMFVolumePreset alloc] init] autorelease];
}

+ (RMFVolumePreset *)VolumePresetWithData:(NSData *)data
{
  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
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
    self.isMounted = NO;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if([aDecoder isKindOfClass:[NSKeyedUnarchiver class]])
  {
    self = [[RMFVolumePreset alloc] init];
    self.volumeLabel = [aDecoder decodeObjectForKey:@"label"];
    self.shouldAutoMount = [aDecoder decodeBoolForKey:@"automount"];
    self.diskSize = [aDecoder decodeIntegerForKey:@"size"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  if([aCoder isKindOfClass:[NSKeyedArchiver class]])
  {
    //[super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.shouldAutoMount forKey:@"automount"];
    [aCoder encodeInteger:self.diskSize forKey:@"size"];
    [aCoder encodeObject:self.volumeLabel forKey:@"label"];
  }
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

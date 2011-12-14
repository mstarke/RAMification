//
//  RMFPresets.m
//  RAMification
//
//  Created by Michael Starke on 27.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFRamdisk.h"

// Defaults
NSString *const RMFDefaultRamdiskLabel = @"Ramdisk";
const NSUInteger RMFDefaultRamdiskSize = 4096;
// NSCodingKeys
NSString *const RMFKeyForLabel = @"label";
NSString *const RMFKeyForAutomount = @"automount";
NSString *const RMFKeyForSize = @"size";


@implementation RMFRamdisk

@synthesize size;
@synthesize label;
@synthesize devicePath;
@synthesize automount;
@synthesize isMounted;

+ (RMFRamdisk *) VolumePresetWithLable:(NSString *)aLabel andSize:(NSUInteger)aSize shouldAutoMount:(BOOL)mount
{
  return [[[RMFRamdisk alloc] initWithLabel:aLabel andSize:aSize shouldMount:mount] autorelease];
}

+ (RMFRamdisk *) VolumePreset
{
  return [[[RMFRamdisk alloc] init] autorelease];
}

+ (RMFRamdisk *)VolumePresetWithData:(NSData *)data
{
  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (id)init
{
  return [self initWithLabel:RMFDefaultRamdiskLabel andSize:RMFDefaultRamdiskSize shouldMount:NO];
}

- (id)initWithLabel:(NSString *)aLable andSize:(NSUInteger)aSize shouldMount:(BOOL)mount{
  self = [super init];
  if (self)
  {
    self.size = aSize;
    if(aLable != nil)
    {
      self.label = aLable;
    }
    else
    {
      self.label = RMFDefaultRamdiskLabel;
    } 
    self.automount = mount;
    self.isMounted = NO;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if([aDecoder isKindOfClass:[NSKeyedUnarchiver class]])
  {
    self = [[RMFRamdisk alloc] init];
    self.label = [aDecoder decodeObjectForKey:RMFKeyForLabel];
    self.automount = [aDecoder decodeBoolForKey:RMFKeyForAutomount];
    self.size = [aDecoder decodeIntegerForKey:RMFKeyForSize];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  if([aCoder isKindOfClass:[NSKeyedArchiver class]])
  {
    //[super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.automount forKey:RMFKeyForAutomount];
    [aCoder encodeInteger:self.size forKey:RMFKeyForSize];
    [aCoder encodeObject:self.label forKey:RMFKeyForLabel];
  }
}

- (BOOL)isEqual:(id)object
{
  BOOL isEqual = NO;
  
  if([object isMemberOfClass:[RMFRamdisk class]])
  {
    RMFRamdisk* other = (RMFRamdisk*)object;
    isEqual = [self.label isEqualToString:other.label];
  }
  return isEqual;
}

@end

//
//  RMFPresets.m
//  RAMification
//
//  Created by Michael Starke on 27.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFRamdisk.h"
#import "RMFAppDelegate.h"
#import "RMFSettingsKeys.h"
#import "RMFSyncDaemon.h"

// NSCodingKeys or for KVC accesssors
NSString *const kRMFRamdiskKeyForLabel = @"label";
NSString *const kRMFRamdiskKeyForAutomount = @"automount";
NSString *const kRMFRamdiskKeyForSize = @"size";
NSString *const kRMFRamdiskKeyForBackupMode = @"backupMode";
NSString *const kRMFRamdiskKeyForVolumeIcon = @"volumeIcon";

static NSDictionary *volumeIconPaths;

@interface RMFRamdisk ()
@property (readwrite) BOOL isDirty;
@property (retain) NSDate *lastBackupDate;


@end

@implementation RMFRamdisk

+ (void)initialize {
  NSBundle *bundle = [NSBundle mainBundle];
  volumeIconPaths = @{ @(RMFDefaultVolumeIcon): [bundle URLForImageResource:@"Removable"]};
}

#pragma mark convinent object creation

+ (RMFRamdisk *) volumePresetWithLable:(NSString *)aLabel andSize:(NSUInteger)aSize shouldAutoMount:(BOOL)mount {
  return [[[RMFRamdisk alloc] initWithLabel:aLabel andSize:aSize shouldMount:mount] autorelease];
}

+ (RMFRamdisk *) volumePreset {
  return [[[RMFRamdisk alloc] init] autorelease];
}

+ (RMFRamdisk *)volumePresetWithData:(NSData *)data {
  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark defaults

+ (NSString *)defaultLabel {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kRMFSettingsKeyLabel];
}

+ (NSUInteger)defaultSize {
  return [[NSUserDefaults standardUserDefaults] integerForKey:kRMFSettingsKeySize];
}


#pragma mark object lifecycle

- (id)init {
  return [self initWithLabel:[RMFRamdisk defaultLabel] andSize:[RMFRamdisk defaultSize] shouldMount:NO];
}

- (id)initWithLabel:(NSString *)aLable andSize:(NSUInteger)aSize shouldMount:(BOOL)mount {
  self = [super init];
  if (self)   {
    self.size = aSize;
    if(aLable != nil) {
      _label = [aLable retain];
    }
    else {
      _label = [[RMFRamdisk defaultLabel] retain];
    }
    _isAutomount = mount;
    _activity = RMFRamdiskIdle;
    _backupMode = RMFNoBackup;
    _lastBackupDate = [NSDate distantPast];
    _volumeIcon = RMFDefaultVolumeIcon;
  }
  return self;
}

- (NSString *)description {
  NSString *description = [NSString stringWithFormat:@"Ramdisk:%@ BDSDevice:%@ DevicePath:%@ Mounted:%i Automount:%i Backup:%i"
                           , _label
                           , _bsdDevice
                           , _volumePath
                           , [self isMounted]
                           , _isAutomount
                           , _backupMode];
  return description;
}

#pragma mark NSCoder
- (id)initWithCoder:(NSCoder *)aDecoder {
  if([aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    self = [[RMFRamdisk alloc] init];
    _label = [[aDecoder decodeObjectForKey:kRMFRamdiskKeyForLabel] retain];
    _isAutomount = [aDecoder decodeBoolForKey:kRMFRamdiskKeyForAutomount];
    _size = [aDecoder decodeIntegerForKey:kRMFRamdiskKeyForSize];
    _backupMode = (RMFRamdiskBackupMode)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForBackupMode];
    _volumeIcon = (RMFRamdiskVolumeIcon)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForVolumeIcon];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    //[super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.isAutomount forKey:kRMFRamdiskKeyForAutomount];
    [aCoder encodeInteger:self.size forKey:kRMFRamdiskKeyForSize];
    [aCoder encodeObject:self.label forKey:kRMFRamdiskKeyForLabel];
    [aCoder encodeInteger:self.backupMode forKey:kRMFRamdiskKeyForBackupMode];
    [aCoder encodeInteger:self.volumeIcon forKey:kRMFRamdiskKeyForVolumeIcon];
  }
}

- (NSURL *)urlForVolumeIcon {
  return [volumeIconPaths objectForKey:@(self.volumeIcon)];
}

- (BOOL)isEqual:(id)object {
  BOOL isEqual = NO;
  if([object isMemberOfClass:[RMFRamdisk class]]) {
    RMFRamdisk* other = (RMFRamdisk*)object;
    isEqual = [self.label isEqualToString:other.label];
    isEqual &= (self.size == other.size);
  }
  return isEqual;
}

- (BOOL)isMounted {
  // Mounted when we got a bds device and a volume path
  return (_bsdDevice != nil && _volumePath != nil);
}

- (void)finishedBackup {
  self.lastBackupDate = [NSDate date];
}

@end

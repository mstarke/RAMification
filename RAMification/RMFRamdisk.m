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
NSString *const kRMFRamdiskKeyForVolumeIconType = @"volumeIconType";
NSString *const kRMFRamdiskKeyForVolumeIcon = @"volumeIcon";
NSString *const kRMFRamdiskKeyForFinderLabelIndex = @"finderLabelIndex";
NSString *const kRMFRamdiskKeyForIsMounted = @"isMounted";
NSString *const kRMFRamdiskKeyForIsDefault = @"isDefault";

// private constants
NSString *const kRMFRamdiskNeverIndexFileName = @".metadata_never_index";
NSString *const kRMFRamdiskIdentifierFile = @".volume_is_ramdisk";
NSString *const RMFRamdiskDefaultLabel = @"RamDisk";
NSUInteger const kRMFRamdiskDefaultSize = 512*1024*1024; // 512 Mb

static NSDictionary *volumeIconImageNames;

@interface RMFRamdisk ()
@property (retain) NSDate *lastBackupDate;
@end

@implementation RMFRamdisk


+ (void)initialize {
  volumeIconImageNames = @{ @(RMFDefaultVolumeIcon): @"Removable"};
  [volumeIconImageNames retain];
}

#pragma mark convinent object creation

+ (RMFRamdisk *) ramdiskWithLabel:(NSString *)aLabel size:(NSUInteger)aSize automount:(BOOL)mount {
  return [[[RMFRamdisk alloc] initWithLabel:aLabel size:aSize automount:mount] autorelease];
}

+ (RMFRamdisk *) defaultRamdisk {
  return [[[RMFRamdisk alloc] init] autorelease];
}

+ (RMFRamdisk *)ramdiskWithData:(NSData *)data {
  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (BOOL)volumeIsRamdiskAtURL:(NSURL *)volumeURL {
  NSString *idFilePath = [[volumeURL path] stringByAppendingPathComponent:kRMFRamdiskIdentifierFile];
  return [[NSFileManager defaultManager] fileExistsAtPath:idFilePath];
}

#pragma mark object lifecycle

- (id)init {
  return [self initWithLabel:RMFRamdiskDefaultLabel size:kRMFRamdiskDefaultSize automount:NO];
}

- (id)initWithLabel:(NSString *)aLable size:(NSUInteger)aSize automount:(BOOL)automount {
  self = [super init];
  if (self)   {
    self.size = aSize;
    if(aLable != nil) {
      self.label = aLable;
    }
    else {
      self.label = RMFRamdiskDefaultLabel;
    }
    _isAutomount = automount;
    _activity = RMFRamdiskIdle;
    _backupMode = RMFNoBackup;
    _lastBackupDate = [NSDate distantPast];
    _volumeIconType = RMFDefaultVolumeIcon;
    _finderLabelIndex = 0;
    _isDefault = NO;
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
    _isDefault = [aDecoder decodeBoolForKey:kRMFRamdiskKeyForIsDefault];
    _size = [aDecoder decodeIntegerForKey:kRMFRamdiskKeyForSize];
    _backupMode = (RMFRamdiskBackupMode)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForBackupMode];
    _volumeIconType = (RMFRamdiskVolumeIcon)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForVolumeIconType];
    _finderLabelIndex = [aDecoder decodeIntegerForKey:kRMFRamdiskKeyForFinderLabelIndex];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    //[super encodeWithCoder:aCoder];
    [aCoder encodeBool:_isAutomount forKey:kRMFRamdiskKeyForAutomount];
    [aCoder encodeBool:_isDefault forKey:kRMFRamdiskKeyForIsDefault];
    [aCoder encodeInteger:_size forKey:kRMFRamdiskKeyForSize];
    [aCoder encodeObject:_label forKey:kRMFRamdiskKeyForLabel];
    [aCoder encodeInteger:_backupMode forKey:kRMFRamdiskKeyForBackupMode];
    [aCoder encodeInteger:_volumeIconType forKey:kRMFRamdiskKeyForVolumeIconType];
    [aCoder encodeInteger:_finderLabelIndex forKey:kRMFRamdiskKeyForFinderLabelIndex];
  }
}

- (BOOL)isEqual:(id)object {
  BOOL isEqual = NO;
  if([object isMemberOfClass:[RMFRamdisk class]]) {
    RMFRamdisk* other = (RMFRamdisk*)object;
    isEqual = [_label isEqualToString:other.label];
    isEqual &= (_size == other.size);
  }
  return isEqual;
}

- (void)finishedBackup {
  self.lastBackupDate = [NSDate date];
}

- (NSImage *)volumeIcon {
  NSString *imageName = [volumeIconImageNames objectForKey:@(self.volumeIconType)];
  return [NSImage imageNamed:imageName];
}

- (void)prepareContent {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(_volumePath == nil) {
    NSLog(@"%@: Warning - no Volume Path set. Could not create Spotlight Index prohibition and ramdisk volume marker!", self);
    return; // No path to work with
  }
  NSString *doNotIndexFile = [_volumePath stringByAppendingPathComponent:kRMFRamdiskNeverIndexFileName];
  NSString *markAsRamdiskFile = [_volumePath stringByAppendingPathComponent:kRMFRamdiskIdentifierFile];
  [fileManager createFileAtPath:markAsRamdiskFile contents:nil attributes:nil];
  [fileManager createFileAtPath:doNotIndexFile contents:nil attributes:nil];
}

- (void)updateLabel {
  NSURL *url = [NSURL fileURLWithPath:self.volumePath isDirectory:YES];
  [url setResourceValue:@(_finderLabelIndex) forKey:NSURLLabelNumberKey error:nil];
}

@end

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
NSString *const kRMFRamdiskKeyForUUID = @"uuid";
NSString *const kRMFRamdiskIdentifierFile = @".volume_is_ramdisk";

// private constants
NSString *const kRMFRamdiskNeverIndexFileName = @".metadata_never_index";
NSString *const RMFRamdiskDefaultLabel = @"RamDisk";
NSUInteger const kRMFRamdiskDefaultSize = 512*1024*1024; // 512 Mb

static NSDictionary *volumeIconImageNames;

@interface RMFRamdisk ()
@property (retain) NSDate *lastBackupDate;
@property (retain) NSString *uuid;
- (NSString *)_generateUUID;
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

+ (NSString *)uuidOfRamdiskAtAURL:(NSURL *)volumeURL success:(BOOL *)success {
  
  assert(success != 0);
  
  NSError *readError = nil;
  NSURL *idFileURL = [volumeURL URLByAppendingPathComponent:kRMFRamdiskIdentifierFile];
  NSString *uuid = [NSString stringWithContentsOfURL:idFileURL encoding:NSUTF8StringEncoding error:&readError];
  
  if(readError != nil) {
    NSLog(@"Warning. Unable to Read UUID at URL:%@. %@", volumeURL, [readError localizedDescription]);
    *success = NO;
  }
  else {
    *success = YES;
  }
  return uuid;
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
    self.uuid = [self _generateUUID];
  }
  return self;
}

- (NSString *)description {
  NSString *description = [NSString stringWithFormat:@"Ramdisk:%@ UUID:%@ BDSDevice:%@ DevicePath:%@ Mounted:%i Automount:%i Backup:%i"
                           , _label
                           , _uuid
                           , _bsdDevice
                           , _volumeURL
                           , [self isMounted]
                           , _isAutomount
                           , _backupMode];
  return description;
}

#pragma mark NSCoder
- (id)initWithCoder:(NSCoder *)aDecoder {
  if([aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    self = [[RMFRamdisk alloc] init];
    // retain the objects
    self.label = [aDecoder decodeObjectForKey:kRMFRamdiskKeyForLabel];
    self.uuid = [aDecoder decodeObjectForKey:kRMFRamdiskKeyForUUID];
    // assing alementary types
    _isAutomount = [aDecoder decodeBoolForKey:kRMFRamdiskKeyForAutomount];
    _isDefault = [aDecoder decodeBoolForKey:kRMFRamdiskKeyForIsDefault];
    _size = [aDecoder decodeIntegerForKey:kRMFRamdiskKeyForSize];
    _backupMode = (RMFRamdiskBackupMode)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForBackupMode];
    _volumeIconType = (RMFRamdiskVolumeIcon)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForVolumeIconType];
    _finderLabelIndex = [aDecoder decodeIntegerForKey:kRMFRamdiskKeyForFinderLabelIndex];
    
    // UUID is missing. Generate one!
    if(nil == _uuid) {
      self.uuid = [self _generateUUID];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    
    //[super encodeWithCoder:aCoder];
    // encode objects
    [aCoder encodeObject:_label forKey:kRMFRamdiskKeyForLabel];
    [aCoder encodeObject:_uuid forKey:kRMFRamdiskKeyForUUID];
    
    // encode integral types
    [aCoder encodeBool:_isAutomount forKey:kRMFRamdiskKeyForAutomount];
    [aCoder encodeBool:_isDefault forKey:kRMFRamdiskKeyForIsDefault];
    [aCoder encodeInteger:_size forKey:kRMFRamdiskKeyForSize];
    [aCoder encodeInteger:_backupMode forKey:kRMFRamdiskKeyForBackupMode];
    [aCoder encodeInteger:_volumeIconType forKey:kRMFRamdiskKeyForVolumeIconType];
    [aCoder encodeInteger:_finderLabelIndex forKey:kRMFRamdiskKeyForFinderLabelIndex];
  }
}

- (BOOL)isEqual:(id)object {
  BOOL isEqual = NO;
  if([object isMemberOfClass:[RMFRamdisk class]]) {
    RMFRamdisk* other = (RMFRamdisk*)object;
    isEqual = [_uuid isEqualToString:other.uuid];
  }
  return isEqual;
}

#pragma mark custom setter/getter
- (NSImage *)volumeIcon {
  NSString *imageName = [volumeIconImageNames objectForKey:@(self.volumeIconType)];
  return [NSImage imageNamed:imageName];
}

- (void)setFinderLabelIndex:(NSUInteger)finderLabelIndex {
  if(_finderLabelIndex != finderLabelIndex) {
    _finderLabelIndex = finderLabelIndex;
    if(_isMounted) {
      [self updateFinderLabel];
    }
  }
}

- (void)didFinishBackup {
  self.lastBackupDate = [NSDate date];
}

- (void)prepareContent {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(_volumeURL == nil) {
    NSLog(@"%@: Warning - no Volume Path set. Could not create Spotlight Index prohibition and ramdisk volume marker!", self);
    return; // No path to work with
  }
  NSURL *doNotIndexFileURL = [_volumeURL URLByAppendingPathComponent:kRMFRamdiskNeverIndexFileName];
  NSURL *markAsRamdiskFileURL = [_volumeURL URLByAppendingPathComponent:kRMFRamdiskIdentifierFile];
  NSData *uuidData = [_uuid dataUsingEncoding:NSUTF8StringEncoding];
  if(NO == [fileManager fileExistsAtPath:[doNotIndexFileURL path]]) {
    [fileManager createFileAtPath:[markAsRamdiskFileURL path] contents:uuidData attributes:nil];
  }
  if(NO ==[fileManager fileExistsAtPath:[markAsRamdiskFileURL path]]) {
    [fileManager createFileAtPath:[doNotIndexFileURL path] contents:nil attributes:nil];
  }
}

- (void)updateFinderLabel {
  [_volumeURL setResourceValue:@(_finderLabelIndex) forKey:NSURLLabelNumberKey error:nil];
}

- (NSString *)_generateUUID {
  CFUUIDRef uuidRef = CFUUIDCreate(CFAllocatorGetDefault());
  CFStringRef uuidStringRef = CFUUIDCreateString(CFAllocatorGetDefault(), uuidRef);
  
  NSString *uuid = [NSString stringWithString:(NSString *)uuidStringRef];
  
  // clean up
  CFRelease(uuidStringRef);
  CFRelease(uuidRef);
  
  return uuid;
}

@end

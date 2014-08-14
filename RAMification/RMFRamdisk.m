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
NSString *const kRMFRamdiskKeyForMountScript = @"mountScript";
NSString *const kRMFRamdiskKeyForHasMountScript = @"hasMountScript";


// Filenames
NSString *const kRMFRamdiskIdentifierFile = @".volume_is_ramdisk";
NSString *const kRMFRamdiskVolumeIconFileName = @"VolumeIcon.icns";

// private constants
NSString *const kRMFRamdiskNeverIndexFileName = @".metadata_never_index";
NSString *const RMFRamdiskDefaultLabel = @"RamDisk";
NSUInteger const kRMFRamdiskDefaultSize = 512*1024*1024; // 512 Mb

static NSDictionary *volumeIconImageNames;

@interface RMFRamdisk ()

@property (strong) NSDate *lastBackupDate;
@property (strong) NSUUID *uuid;
@property (assign, nonatomic) BOOL hasMountScript;
@end


@implementation RMFRamdisk

#pragma mark convinent object creation

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    volumeIconImageNames = @{ @(RMFDefaultVolumeIcon): @"Removable"};
  });
}

+ (RMFRamdisk *) ramdiskWithLabel:(NSString *)aLabel size:(NSUInteger)aSize automount:(BOOL)mount {
  return [[RMFRamdisk alloc] initWithLabel:aLabel size:aSize automount:mount];
}

+ (RMFRamdisk *) defaultRamdisk {
  return [[RMFRamdisk alloc] init];
}

+ (RMFRamdisk *)ramdiskWithData:(NSData *)data {
  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (BOOL)volumeIsRamdiskAtURL:(NSURL *)volumeURL {
  if(![volumeURL isFileURL]) {
    return NO; // No valid file URL
  }
  NSURL *idFileURL = [volumeURL URLByAppendingPathComponent:kRMFRamdiskIdentifierFile];
  NSError *error = nil;
  BOOL isReachable = [idFileURL checkResourceIsReachableAndReturnError:&error];
  if(nil != error) {
    NSLog(@"%@: Volume at URL %@ is not Ramdisk. %@", [self class], volumeURL, [error localizedDescription]);
  }
  return isReachable;
}

+ (NSUUID *)uuidOfRamdiskAtAURL:(NSURL *)volumeURL success:(BOOL *)success {
  
  if(success == 0) {
    NSException *invalidArgumentException = [NSException exceptionWithName:NSInvalidArgumentException reason:@"Success pointer cannot be NULL" userInfo:nil];
    @throw invalidArgumentException;
  }
  
  if(![volumeURL isFileURL]) {
    success = NO;
    return nil; // No valid file URL
  }
  
  NSError *readError = nil;
  NSURL *idFileURL = [volumeURL URLByAppendingPathComponent:kRMFRamdiskIdentifierFile];
  NSData *uuidData = [NSData dataWithContentsOfURL:idFileURL options:0 error:&readError];
  if(readError != nil) {
    NSLog(@"Warning. Unable to Read UUID at URL:%@. %@", volumeURL, [readError localizedDescription]);
    *success = NO;
  }
  else {
    *success = YES;
  }
  uuid_t uuidBytes;
  [uuidData getBytes:uuidBytes length:MIN([uuidData length], sizeof(uuidBytes))];
  return [[NSUUID alloc] initWithUUIDBytes:uuidBytes];
}

+ (BOOL)volumeHasCustomIconAtURL:(NSURL *)volumeURL {
  if(![volumeURL isFileURL]) {
    return NO; // No valid volume URL given
  }
  NSURL *volumeIconURL = [volumeURL URLByAppendingPathComponent:kRMFRamdiskVolumeIconFileName];
  return [volumeIconURL checkResourceIsReachableAndReturnError:nil];
}

#pragma mark object lifecycle

- (id)init {
  return [self initWithLabel:RMFRamdiskDefaultLabel size:kRMFRamdiskDefaultSize automount:NO];
}

- (id)initWithLabel:(NSString *)aLable size:(NSUInteger)aSize automount:(BOOL)automount {
  self = [super init];
  if (self)   {
    _size = aSize;
    if(aLable != nil) {
      _label = aLable;
    }
    else {
      _label = RMFRamdiskDefaultLabel;
    }
    _isAutomount = automount;
    _activity = RMFRamdiskIdle;
    _backupMode = RMFNoBackup;
    _lastBackupDate = [NSDate distantPast];
    _volumeIconType = RMFDefaultVolumeIcon;
    _finderLabelIndex = 0;
    _isDefault = NO;
    _uuid = [[NSUUID alloc] init];
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
    self = [super init];
    // retain the objects
    _label = [aDecoder decodeObjectForKey:kRMFRamdiskKeyForLabel];
    id uuid = [aDecoder decodeObjectForKey:kRMFRamdiskKeyForUUID];
    if([uuid isKindOfClass:[NSString class]]) {
      _uuid = [[NSUUID alloc] initWithUUIDString:uuid];
    }
    else if( [uuid isKindOfClass:[NSData class]]) {
      uuid_t uuidBytes = {0};
      [uuid getBytes:uuidBytes length:sizeof([uuid length])];
      _uuid = [[NSUUID alloc] initWithUUIDBytes:uuidBytes];
    }
    // assing alementary types
    _isAutomount = [aDecoder decodeBoolForKey:kRMFRamdiskKeyForAutomount];
    _isDefault = [aDecoder decodeBoolForKey:kRMFRamdiskKeyForIsDefault];
    _size = [aDecoder decodeIntegerForKey:kRMFRamdiskKeyForSize];
    _backupMode = (RMFRamdiskBackupMode)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForBackupMode];
    _volumeIconType = (RMFRamdiskVolumeIcon)[aDecoder decodeIntegerForKey:kRMFRamdiskKeyForVolumeIconType];
    _finderLabelIndex = [aDecoder decodeIntegerForKey:kRMFRamdiskKeyForFinderLabelIndex];
    _mountScript = [aDecoder decodeObjectForKey:kRMFRamdiskKeyForMountScript];
    
    // UUID is missing. Generate one!
    if(nil == _uuid) {
      _uuid = [[NSUUID alloc] init];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    // encode objects
    [aCoder encodeObject:_label forKey:kRMFRamdiskKeyForLabel];
    [aCoder encodeObject:_uuid forKey:kRMFRamdiskKeyForUUID];
    [aCoder encodeObject:_mountScript forKey:kRMFRamdiskKeyForMountScript];
    
    // encode integral types
    [aCoder encodeBool:_isAutomount forKey:kRMFRamdiskKeyForAutomount];
    [aCoder encodeBool:_isDefault forKey:kRMFRamdiskKeyForIsDefault];
    [aCoder encodeInteger:_size forKey:kRMFRamdiskKeyForSize];
    [aCoder encodeInteger:_backupMode forKey:kRMFRamdiskKeyForBackupMode];
    [aCoder encodeInteger:_volumeIconType forKey:kRMFRamdiskKeyForVolumeIconType];
    [aCoder encodeInteger:_finderLabelIndex forKey:kRMFRamdiskKeyForFinderLabelIndex];
  }
}

- (void)dealloc
{
  NSLog(@"%@: Deallocated %@", [self class], self);
}

- (BOOL)isEqual:(id)object {
  BOOL isEqual = NO;
  if([object isMemberOfClass:[RMFRamdisk class]]) {
    RMFRamdisk* other = (RMFRamdisk*)object;
    isEqual = [[self.uuid UUIDString] isEqualToString:[other.uuid UUIDString]];
  }
  return isEqual;
}

#pragma mark custom setter/getter
- (BOOL)hasMountScript {
  return (self.mountScript != nil);
}

- (void)setHasMountScript:(BOOL)hasMountScript {
  return; // Do nothing as this property is Read only.
}


- (NSImage *)volumeIcon {
  NSString *imageName = volumeIconImageNames[@(self.volumeIconType)];
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
  uuid_t uuidBytes = {0};
  [self.uuid getUUIDBytes:uuidBytes];
  NSData *uuidData = [[NSData alloc] initWithBytesNoCopy:uuidBytes length:sizeof(uuidBytes) freeWhenDone:NO];
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
@end

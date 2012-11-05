//
//  RMFPresets.h
//  RAMification
//
//  Created by Michael Starke on 27.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

// NSKeyArchiver Keys
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForLabel;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForAutomount;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForSize;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForBackupMode;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForVolumeIcon;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForVolumeIconType;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForFinderLabelIndex;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForIsMounted;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForIsDefault;

typedef enum RMFRamdiskAcitivyMode {
  RMFRamdiskIdle, // Ramdisk is ready
  RMFRamdiskRestoring, // Ramdisk is being restored
  RMFRamdiskBackup, // Ramdisk is being backed up
} RMFRamdiskAcitivity;

typedef enum RMFRamdiskBackupModeType {
  RMFNoBackup,
  RMFBackupPeriodically,
  RMFBackupOnEject,
  RMFBackupModeCount // Counter not to be assigned!
} RMFRamdiskBackupMode;

typedef enum RMFRamdiskVolumeIconType {
  RMFDefaultVolumeIcon,
  RMFVolumeIconCount // Counter not to be assigned!
} RMFRamdiskVolumeIcon;

// A Ramdisk structure for holding all the information about a ramdisk
// also used for favourites management
@interface RMFRamdisk : NSObject <NSCoding>

@property (retain) NSString *label;
@property (assign) NSUInteger size;
@property (retain) NSString *volumePath;
@property (retain) NSString *bsdDevice;
@property (retain, readonly) NSString *uuid;
@property (assign) RMFRamdiskAcitivity activity;
@property (assign) RMFRamdiskBackupMode backupMode;
@property (assign) RMFRamdiskVolumeIcon volumeIconType;
@property (assign) NSUInteger finderLabelIndex;
@property (nonatomic, readonly) NSImage *volumeIcon;
@property (retain, readonly) NSDate *lastBackupDate;
@property (assign) BOOL isMounted;
@property (assign) BOOL isAutomount;
@property (assign) BOOL isDefault;

+ (RMFRamdisk *)ramdiskWithData:(NSData *)data;
+ (RMFRamdisk *)ramdiskWithLabel:(NSString *)aLabel size:(NSUInteger)aSize automount:(BOOL)mount;
+ (RMFRamdisk *)defaultRamdisk;
+ (BOOL)volumeIsRamdiskAtURL:(NSURL *)volumeURL;
+ (NSString *)uuidOfRamdiskAtAURL:(NSURL *)volumeURL success:(BOOL *)success;

- (id)initWithLabel:(NSString*)aLable size:(NSUInteger)aSize automount:(BOOL)automount;
// Call this function to indicate that this ramdisk was just backed up
- (void)finishedBackup;
- (void)prepareContent;
- (void)updateFinderLabel;

@end

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
APPKIT_EXTERN NSString *const kRMFRamdiskIdentifierFile;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForMountScript;
APPKIT_EXTERN NSString *const kRMFRamdiskKeyForHasMountScript;

// Usefull constants
APPKIT_EXTERN NSString *const kRMFRamdiskVolumeIconFileName;

@class RMFRamdiskScript;

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
  RMFCustomVolumeIcon,
  RMFVolumeIconCount // Counter not to be assigned!
} RMFRamdiskVolumeIcon;

// A Ramdisk structure for holding all the information about a ramdisk
// also used for favourites management
@interface RMFRamdisk : NSObject <NSCoding>

@property (strong) NSString *label;
@property (assign) NSUInteger size;
@property (strong) NSURL *volumeURL;
@property (strong) NSString *bsdDevice;
@property (strong, readonly) NSUUID *uuid;
@property (assign) RMFRamdiskAcitivity activity;
@property (assign) RMFRamdiskBackupMode backupMode;
@property (assign) RMFRamdiskVolumeIcon volumeIconType;
@property (nonatomic, assign) NSUInteger finderLabelIndex;
@property (weak, nonatomic, readonly) NSImage *volumeIcon;
@property (strong) RMFRamdiskScript *mountScript;
@property (strong, readonly) NSDate *lastBackupDate;
@property (assign) BOOL isMounted;
@property (assign) BOOL isAutomount;
@property (assign) BOOL isDefault;
@property (assign, readonly, nonatomic) BOOL hasMountScript;

+ (RMFRamdisk *)ramdiskWithData:(NSData *)data;
+ (RMFRamdisk *)ramdiskWithLabel:(NSString *)aLabel size:(NSUInteger)aSize automount:(BOOL)mount;
+ (RMFRamdisk *)defaultRamdisk;
+ (BOOL)volumeIsRamdiskAtURL:(NSURL *)volumeURL;
+ (NSUUID *)uuidOfRamdiskAtAURL:(NSURL *)volumeURL success:(BOOL *)success;
+ (BOOL)volumeHasCustomIconAtURL:(NSURL *)volumeURL;

- (id)initWithLabel:(NSString*)aLable size:(NSUInteger)aSize automount:(BOOL)automount;
// Call this function to indicate that this ramdisk was just backed up
- (void)didFinishBackup;
- (void)prepareContent;
- (void)updateFinderLabel;

@end

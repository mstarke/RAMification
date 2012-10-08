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

@property (retain) NSString* label;
@property (assign) NSUInteger size;
@property (retain) NSString *volumePath;
@property (retain) NSString *bsdDevice;
@property (assign) RMFRamdiskAcitivity activity;
@property (assign) RMFRamdiskBackupMode backupMode;
@property (assign) RMFRamdiskVolumeIcon volumeIconType;
@property (nonatomic, readonly) NSImage *volumeIcon;
@property (retain, readonly) NSDate *lastBackupDate;
@property (assign) BOOL isAutomount;
@property (readonly) BOOL isDirty;

+ (RMFRamdisk *)volumePresetWithData:(NSData *)data;
+ (RMFRamdisk *)volumePresetWithLable:(NSString *)aLabel andSize:(NSUInteger)aSize shouldAutoMount:(BOOL)mount;
+ (RMFRamdisk *)volumePreset;
+ (NSString *)defaultLabel;
+ (NSUInteger)defaultSize;

- (id)initWithLabel:(NSString*)aLable andSize:(NSUInteger)aSize shouldMount:(BOOL)mount;
// Call this function to indicate that this ramdisk was just backed up
- (void)finishedBackup;
// is the RAM disk mounted?
- (BOOL)isMounted;


@end

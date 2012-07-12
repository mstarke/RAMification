//
//  RMFPresets.h
//  RAMification
//
//  Created by Michael Starke on 27.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

// NSKeyArchiver Keys
extern NSString *const RMFKeyForLabel;
extern NSString *const RMFKeyForAutomount;
extern NSString *const RMFKeyForSize;
extern NSString *const RMFKeyForBackupEnabled;

typedef enum RMFRamdiskAcitivyMode {
  RMFRamdiskIdle, // Ramdisk is ready
  RMFRamdiskRestoring, // Ramdisk is being restored
  RMFRamdiskBackup, // Ramdisk is being backed up
} RMFRamdiskAcitivity;

// A Ramdisk structure for holding all the information about a ramdisk
// also used for favourites management
@interface RMFRamdisk : NSObject <NSCoding>

@property (nonatomic, retain, setter=setLabel:) NSString* label;
@property (nonatomic, assign, setter=setSize:) NSUInteger size;
@property (retain) NSString* devicePath;
@property (assign) BOOL isAutomount;
@property (nonatomic, assign, setter=setIsMounted:) BOOL isMounted;
@property (assign) BOOL isBackupEnabled;
@property (assign) RMFRamdiskAcitivity activity;
// indicates that changes were made after mounting
@property (readonly) BOOL isDirty;

+ (RMFRamdisk*) volumePresetWithData:(NSData*)data;
+ (RMFRamdisk*) volumePresetWithLable:(NSString*)aLabel andSize:(NSUInteger)aSize shouldAutoMount:(BOOL)mount;
+ (RMFRamdisk*) volumePreset;
+ (NSString*) defaultLabel;
+ (NSUInteger) defaultSize;

- (id) initWithLabel:(NSString*)aLable andSize:(NSUInteger)aSize shouldMount:(BOOL)mount;

@end

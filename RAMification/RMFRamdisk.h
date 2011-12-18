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

// A Ramdisk structure for holding all the information about a ramdisk
// also used for favourites management
@interface RMFRamdisk : NSObject <NSCoding>

@property (retain) NSString* label;
@property (assign) NSUInteger size;
@property (retain) NSString* devicePath;
@property (assign) BOOL automount;
@property (assign) BOOL isMounted;
@property (assign) BOOL backup;

+ (RMFRamdisk*) VolumePresetWithData:(NSData*)data;
+ (RMFRamdisk*) VolumePresetWithLable:(NSString*)aLabel andSize:(NSUInteger)aSize shouldAutoMount:(BOOL)mount;
+ (RMFRamdisk*) VolumePreset;
+ (NSString*) defaultLabel;
+ (NSUInteger) defaultSize;

- (id) initWithLabel:(NSString*)aLable andSize:(NSUInteger)aSize shouldMount:(BOOL)mount;

@end

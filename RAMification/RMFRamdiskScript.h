//
//  RMFRamdiskScript.h
//  RAMification
//
//  Created by Michael Starke on 07.04.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kRMFRamdiskScriptKeyForLanguage;
extern NSString *const kRMFRamdiskScriptKeyForScript;


@class RMFRamdisk;

typedef NS_ENUM(unsigned int, RMFScriptLanguage) {
  RMFUnknownLanguage, // Interal state. Should not occur on valid object
  RMFShellScript,
  RMFAppleScript
};

@interface RMFRamdiskScript : NSObject <NSCoding>

+ (NSString *)labelForLanguage:(RMFScriptLanguage)language;
/*
 Returns a Dictionary with the available Languages as keys.
 NSNumbers wrapping RMFScriptLanguage and NSStrings as values with the descripive names;
 */
+ (NSDictionary *)availableLanguages;

@property (strong) NSString *script;
@property (assign) RMFScriptLanguage language;

/*
 Designated initalizer
 */
- (instancetype) initWithScript:(NSString *)script language:(RMFScriptLanguage)language NS_DESIGNATED_INITIALIZER;

/* Executed the Script in the Context of a Ramdisk*/
- (void)executeForRamdisk:(RMFRamdisk *)ramdisk;

@end

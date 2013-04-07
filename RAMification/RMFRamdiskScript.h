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

typedef enum {
  RMFUnknownLanguage, // Interal state. Should not occur on valid object
  RMFShellScript,
  RMFAppleScript
} RMFScriptLanguage;

@interface RMFRamdiskScript : NSObject <NSCoding>

+ (NSString *)labelForLanguage:(RMFScriptLanguage)language;
/*
 Returns a Dictionary with the available Languages as keys.
 NSNumbers wrapping RMFScriptLanguage and NSStrings as values with the descripive names;
 */
+ (NSDictionary *)availableLanguages;

@property (retain) NSString *script;
@property (assign) RMFScriptLanguage language;

/*
 Designated initalizer
 */
- initWithScript:(NSString *)script language:(RMFScriptLanguage)language;

/* Executed the Script in the Context of a Ramdisk*/
- (void)executeForRamdisk:(RMFRamdisk *)ramdisk;

@end

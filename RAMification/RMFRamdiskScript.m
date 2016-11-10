//
//  RMFRamdiskScript.m
//  RAMification
//
//  Created by Michael Starke on 07.04.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "RMFRamdiskScript.h"

NSString *const kRMFRamdiskScriptKeyForLanguage = @"language";
NSString *const kRMFRamdiskScriptKeyForScript = @"script";

@implementation RMFRamdiskScript

+ (NSString *)labelForLanguage:(RMFScriptLanguage)language {
  NSDictionary *labels = [self availableLanguages];
  return labels[@(language)];
}

+ (NSDictionary *)availableLanguages {
  return @{
           @(RMFAppleScript) : @"Apple Script",
           @(RMFShellScript) : @"Shell Script"
           };
}

/*
 Designated Initalizer
 */
- (instancetype)initWithScript:(NSString *)script language:(RMFScriptLanguage)language {
  self = [super init];
  if(self){
    _language = language;
    _script = script;
  }
  return self;
}

- (instancetype)init {
  return [self initWithScript:nil language:RMFUnknownLanguage];
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if([aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    self = [super init];
    if(self) {
      _language = (RMFScriptLanguage)[aDecoder decodeIntegerForKey:kRMFRamdiskScriptKeyForLanguage];
      _script = [aDecoder decodeObjectOfClass:[NSString class] forKey:kRMFRamdiskScriptKeyForScript];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeInteger:self.language forKey:kRMFRamdiskScriptKeyForLanguage];
  [aCoder encodeObject:self.script forKey:kRMFRamdiskScriptKeyForScript];
}

- (void)executeForRamdisk:(RMFRamdisk *)ramdisk {
  //run the script - preferably deffered?
}

@end

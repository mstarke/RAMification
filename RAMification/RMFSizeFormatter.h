//
//  RMFSizeFormater.h
//  RAMification
//
//  Created by Michael Starke on 18.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

OBJC_EXTERN NSString *const RMFSizeFormatterValueKey;// the value
OBJC_EXTERN NSString *const RMFSizeFormatterSuffixKey; // the suffix for the number

typedef enum RMFSizeSuffixType {
  RMFSizeSuffixNone,
  RMFSizeSuffixKilo,
  RMFSizeSuffixMega,
  RMFSizeSuffixGiga,
  RMFSizeSuffixCount // Count value, do not use!
} RMFSizeSuffix;

@interface RMFSizeFormatter : NSFormatter

+ (NSString *)nameForSuffix:(RMFSizeSuffix)suffix;
+ (NSNumber *)exponentVorSuffix:(RMFSizeSuffix)suffix;
+ (RMFSizeSuffix)suffixForString:(NSString *)string;
+ (NSDictionary *)suffixExponents;
+ (NSDictionary *)suffixNames;

@end

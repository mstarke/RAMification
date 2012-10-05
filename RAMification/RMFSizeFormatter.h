//
//  RMFSizeFormater.h
//  RAMification
//
//  Created by Michael Starke on 18.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

// We use non-SI suffixes so power of 2 multiplyer
typedef enum RMFSizeSuffixType {
  RMFSizeSuffixNone,
  RMFSizeSuffixKilo,
  RMFSizeSuffixMega,
  RMFSizeSuffixGiga, // Giga
  RMFSizeSuffixCount // Count value, do not use!
} RMFSizeSuffix;

@interface RMFSizeFormatter : NSFormatter
/*
 Convenience method for an autoreleased new formatter
 @returns a new autoreleases formatter
 */
+ (id)formatter;

/*
 @returns the name for a given suffix
 */
+ (NSString *)nameForSuffix:(RMFSizeSuffix)suffix;
/*
 @returns the exponente for a fiven suffix
 */
+ (NSNumber *)exponentForSuffix:(RMFSizeSuffix)suffix;
/*
 @returns the suffix parsed form the given string
 */
+ (RMFSizeSuffix)suffixForString:(NSString *)string;
/*
 @retuns the global mapping from suffix to exponent
 */
+ (NSDictionary *)suffixExponents;
/*
 @returns the global mapping form suffix to name
 */
+ (NSDictionary *)suffixNames;

@end

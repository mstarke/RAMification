//
//  RMFSizeFormater.m
//  RAMification
//
//  Created by Michael Starke on 18.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSizeFormatter.h"

static NSDictionary *RMFSuffixNames;
static NSDictionary *RMFSuffixExponents;

NSString *const kRMFSizeFormatterValueKey = @"RMFSizeFormatterValueKey";
NSString *const kRMFSizeFormatterSuffixKey = @"RMFSizeFormatterSuffixKey"; 

// We use non-SI suffixes so power of 2 multiplyer
typedef enum RMFSizeSuffixType {
  RMFSizeSuffixNone, // Byte
  RMFSizeSuffixKilo, // Kilobyte
  RMFSizeSuffixMega, // Megabyte
  RMFSizeSuffixGiga, // Gigabyte
  RMFSizeSuffixCount // Count value, do not use!
} RMFSizeSuffix;

@interface RMFSizeFormatter (private)

+ (NSDictionary *)sizeRepresentationForNumber:(NSNumber *)number;
+ (NSString *)stringForSizeRepresentation:(NSDictionary *)dict;
+ (NSDictionary *)dictForSuffix:(RMFSizeSuffix)suffix andValue:(double)value;
+ (NSString *)nameForSuffix:(RMFSizeSuffix)suffix;
+ (NSNumber *)exponentForSuffix:(RMFSizeSuffix)suffix;
+ (RMFSizeSuffix)suffixForString:(NSString *)string;
@end


@implementation RMFSizeFormatter

+ (void)initialize {
  // Initalize basic lookup structures
  RMFSuffixExponents = @{ @(RMFSizeSuffixNone): @0, @(RMFSizeSuffixKilo): @1, @(RMFSizeSuffixMega): @2, @(RMFSizeSuffixGiga): @3 };
  [RMFSuffixExponents retain];
  RMFSuffixNames = @{ @(RMFSizeSuffixNone): @"byte", @(RMFSizeSuffixKilo): @"Kb", @(RMFSizeSuffixMega): @"Mb", @(RMFSizeSuffixGiga): @"Gb" };
  [RMFSuffixNames retain];
}

+ (NSString *)nameForSuffix:(RMFSizeSuffix)suffix {
  return RMFSuffixNames[@((int)suffix)];
  
}

+ (NSNumber *)exponentForSuffix:(RMFSizeSuffix)suffix {
  return RMFSuffixExponents[@((int)suffix)];
}

+ (NSDictionary *)dictForSuffix:(RMFSizeSuffix)suffix andValue:(double)value {
  return @{kRMFSizeFormatterSuffixKey: @((int)suffix),
          kRMFSizeFormatterValueKey: @(value)};
}

+ (NSDictionary *)sizeRepresentationForNumber:(NSNumber *)number {
  NSUInteger suffixIndex = 0;
  double value = [number doubleValue];
  // loop through suffixes and count exponents
  while((value / 1024.0) >= 1 && suffixIndex < (RMFSizeSuffixCount - 1)) {
    suffixIndex++;
    value /= 1024.0;
  }
  return [RMFSizeFormatter dictForSuffix:(RMFSizeSuffix)suffixIndex andValue:value];
}

+ (NSString *)stringForSizeRepresentation:(NSDictionary *)dict {
  RMFSizeSuffix suffix = [dict[kRMFSizeFormatterSuffixKey] intValue];
  NSString *suffixName = [RMFSizeFormatter nameForSuffix:suffix];
  const double preciseValue = [dict[kRMFSizeFormatterValueKey] doubleValue];
  const double displayValue = (floor(preciseValue * 100) / 100);
  const double delta = preciseValue - displayValue;
  NSString *formatString = ( delta >= 0.01 ) ? @"%.0f %@" : @"%.2f %@";
  return [NSString stringWithFormat:formatString, [dict[kRMFSizeFormatterValueKey] doubleValue], suffixName];
}

+ (RMFSizeSuffix)suffixForString:(NSString *)string {
  BOOL (^filterBlock)(id,id,BOOL*);
  
  filterBlock = ^BOOL(id key, id value, BOOL *stop){
    NSString *suffixString = value;
    NSComparisonResult result;
    result = [string caseInsensitiveCompare:suffixString];
    return result == NSOrderedSame;
  };
  
  NSSet *matchingSuffixes = [RMFSuffixNames keysOfEntriesPassingTest:filterBlock];
  if([matchingSuffixes count] > 1){
    NSLog(@"%@: Found multiple candidates: %@ for suffix:%@.", self, matchingSuffixes, string);
  }
  return [[matchingSuffixes anyObject] intValue];
}

#pragma mark convenicen lifecycle

+ (id)formatter {
  return [[[RMFSizeFormatter alloc] init] autorelease];
}

#pragma mark NSFormatter overrides

// sets the Object to an NSNumber with the correct value for the found suffix.
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  NSScanner *numberScanner = [NSScanner scannerWithString:string];
  double value;
  BOOL foundDouble = [numberScanner scanDouble:&value];
  if(foundDouble) {
    NSString *suffixPart = [string substringFromIndex:[numberScanner scanLocation]];
    NSString *cleanSuffix = [suffixPart stringByReplacingOccurrencesOfString:@" " withString:@""];
    RMFSizeSuffix suffixType = [RMFSizeFormatter suffixForString:cleanSuffix];
    *anObject = @(value * (double)pow( 1024, (NSUInteger)suffixType));
  }
  
  return foundDouble;
}
// Just add a suffix to high values. We try to minimize the precision to 2 decimals
- (NSString *)stringForObjectValue:(id)obj {
  if([obj isKindOfClass:[NSNumber class]]) {
    NSDictionary *dict = [RMFSizeFormatter sizeRepresentationForNumber:obj];
    return [RMFSizeFormatter stringForSizeRepresentation:dict];
  }
  return nil;
}

//- (BOOL)isPartialStringValid:(NSString *)partialString
//            newEditingString:(NSString **)newString
//            errorDescription:(NSString **)error {
//  return true;
//}
//
//- (BOOL)isPartialStringValid:(NSString **)partialStringPtr
//       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
//              originalString:(NSString *)origString
//       originalSelectedRange:(NSRange)origSelRange
//            errorDescription:(NSString **)error {
//  return true;
//}

@end

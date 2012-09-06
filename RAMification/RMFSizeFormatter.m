//
//  RMFSizeFormater.m
//  RAMification
//
//  Created by Michael Starke on 18.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSizeFormatter.h"

static NSDictionary *suffixNameDict;
static NSDictionary *suffixExponentDict;


NSString *const RMFSizeFormatterValueKey = @"RMFSizeFormatterValueKey";
NSString *const RMFSizeFormatterSuffixKey = @"RMFSizeFormatterSuffixKey"; 

@interface RMFSizeFormatter ()
+ (NSDictionary *)sizeRepresentationForNumber:(NSNumber *)number;
+ (NSString *)stringForSizeRepresentation:(NSDictionary *)dict;
+ (NSDictionary *)dictForSuffix:(RMFSizeSuffix)suffix andValue:(double)value;
@end


@implementation RMFSizeFormatter

+ (NSDictionary *)suffixExponents {
  if(suffixExponentDict == nil) {
    NSArray *keys = [NSArray arrayWithObjects:[NSNumber numberWithInt:RMFSizeSuffixNone]
                     ,[NSNumber numberWithInt:RMFSizeSuffixKilo]
                     ,[NSNumber numberWithInt:RMFSizeSuffixMega]
                     ,[NSNumber numberWithInt:RMFSizeSuffixGiga], nil];
    NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:0]
                     ,[NSNumber numberWithInt:1]
                     ,[NSNumber numberWithInt:2]
                     ,[NSNumber numberWithInt:3], nil];
    
    suffixExponentDict = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
  }
  return suffixExponentDict;
}

+ (NSDictionary *)suffixNames {
  if(suffixNameDict == nil) {
    NSArray *objects = [NSArray arrayWithObjects:@"byte", @"Kb", @"Mb", @"Gb", nil];
    NSArray *keys = [NSArray arrayWithObjects:[NSNumber numberWithInt:RMFSizeSuffixNone]
                     ,[NSNumber numberWithInt:RMFSizeSuffixKilo]
                     ,[NSNumber numberWithInt:RMFSizeSuffixMega]
                     ,[NSNumber numberWithInt:RMFSizeSuffixGiga], nil];
    
    suffixNameDict = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
  }
  return suffixNameDict;
}

+ (NSString *)nameForSuffix:(RMFSizeSuffix)suffix {
  return [[RMFSizeFormatter suffixNames] objectForKey:[NSNumber numberWithInt:suffix ]];
  
}

+ (NSNumber *)exponentVorSuffix:(RMFSizeSuffix)suffix {
  return [[RMFSizeFormatter suffixExponents] objectForKey:[NSNumber numberWithInt:suffix ]];
}

+ (NSDictionary *)dictForSuffix:(RMFSizeSuffix)suffix andValue:(double)value {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:suffix], RMFSizeFormatterSuffixKey,
          [NSNumber numberWithDouble:value], RMFSizeFormatterValueKey, nil];
}

+ (NSDictionary *)sizeRepresentationForNumber:(NSNumber *)number {
  NSUInteger suffixIndex = 0;
  double value = [number intValue];
  // loop through suffixes and count exponents
  while((value / 1024.0) >= 1 && suffixIndex < (RMFSizeSuffixCount - 1)) {
    suffixIndex++;
    value /= 1024.0;
  }
  return [RMFSizeFormatter dictForSuffix:(RMFSizeSuffix)suffixIndex andValue:value];
}

+ (NSString *)stringForSizeRepresentation:(NSDictionary *)dict {
  RMFSizeSuffix suffix = [[dict objectForKey:RMFSizeFormatterSuffixKey] intValue];
  NSString *suffixName = [RMFSizeFormatter nameForSuffix:suffix];
  const double preciseValue = [[dict objectForKey:RMFSizeFormatterValueKey] doubleValue];
  const double displayValue = (floor(preciseValue * 100) / 100);
  const double delta = preciseValue - displayValue;
  NSString *formatString = ( delta >= 0.01 ) ? @"%.0f %@" : @"%.2f %@";
  return [NSString stringWithFormat:formatString, [[dict objectForKey:RMFSizeFormatterValueKey] doubleValue], suffixName];
}

+ (RMFSizeSuffix)suffixForString:(NSString *)string {
  BOOL (^filterBlock)(id,id,BOOL*);
  
  filterBlock = ^BOOL(id key, id value, BOOL *stop){
    NSString *suffixString = value;
    NSComparisonResult result;
    result = [string caseInsensitiveCompare:suffixString];
    return result == NSOrderedSame;
  };
  
  NSSet *matchingSuffixes = [[RMFSizeFormatter suffixNames] keysOfEntriesPassingTest:filterBlock];
  if([matchingSuffixes count] > 1){
    NSLog(@"RMFSizeFormatter: Found multiple candidates: %@ for suffix:%@.", matchingSuffixes, string);
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
    *anObject = [NSNumber numberWithDouble:(value * pow( 1024.0, (double)suffixType))];
  }
  
  return foundDouble;
}
// Just add a suffix to high values. We try to minimize the precision to 2 decimals
- (NSString *)stringForObjectValue:(id)obj {
  if([obj isKindOfClass:[NSNumber class]]) {
    NSDictionary *dict = [RMFSizeFormatter sizeRepresentationForNumber:obj];
    return [RMFSizeFormatter stringForSizeRepresentation:dict];
  }
  NSLog(@"%@ Class %@", obj, [obj class]);
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

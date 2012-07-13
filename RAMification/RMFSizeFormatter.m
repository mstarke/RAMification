//
//  RMFSizeFormater.m
//  RAMification
//
//  Created by Michael Starke on 18.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSizeFormatter.h"

static NSDictionary *suffixNames;
static NSDictionary *suffixExponents;


NSString *const RMFSizeFormatterValueKey = @"RMFSizeFormatterValueKey";
NSString *const RMFSizeFormatterSuffixKey = @"RMFSizeFormatterSuffixKey"; 

@interface RMFSizeFormatter ()
//
// Creates  a dictionary that contains the formated represtatntio for the given number
// The keys are defined int \ref RMFSizeFormatDictionaryKey
// Use this dictionary to generate string representations
- (NSDictionary *)sizeRepresentationForNumber:(NSNumber *)number;
@end


@implementation RMFSizeFormatter

+ (NSString *)nameForSuffix:(RMFSizeSuffix)suffix {
  if(suffixNames == nil) {
    NSArray *objects = [NSArray arrayWithObjects:@"", @"Kb", @"Mb", @"Gb", nil];
    NSArray *keys = [NSArray arrayWithObjects:[NSNumber numberWithInt:RMFSizeSuffixNone]
                     ,[NSNumber numberWithInt:RMFSizeSuffixKilo]
                     ,[NSNumber numberWithInt:RMFSizeSuffixMega]
                     ,[NSNumber numberWithInt:RMFSizeSuffixGiga], nil];
    
    suffixNames = [[NSDictionary dictionaryWithObjects:objects forKeys:keys] retain];
  }
  return [suffixNames objectForKey:[NSNumber numberWithInt:suffix ]];

}
+ (NSNumber *)exponentVorSuffix:(RMFSizeSuffix)suffix {
  if(suffixExponents == nil) {
    NSArray *objects = [NSArray arrayWithObjects:@"", @"Kb", @"Mb", @"Gb", nil];
    NSArray *keys = [NSArray arrayWithObjects:[NSNumber numberWithInt:0]
                     ,[NSNumber numberWithInt:1]
                     ,[NSNumber numberWithInt:2]
                     ,[NSNumber numberWithInt:3], nil];
    
    suffixExponents = [[NSDictionary dictionaryWithObjects:objects forKeys:keys] retain];
  }
  return [suffixExponents objectForKey:[NSNumber numberWithInt:suffix]];
}

- (NSDictionary *)sizeRepresentationForNumber:(NSNumber *)number {
  NSUInteger suffixIndex = 0;
  double value = [number intValue];
  while( ( value / 1024.0 ) > 1 ) {
    suffixIndex++;
    value /= 1024.0;
  }
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:suffixIndex], RMFSizeFormatterSuffixKey,
          [NSNumber numberWithDouble:value], RMFSizeFormatterValueKey, nil];
}

- (NSString *)stringForObjectValue:(id)obj {
  if([obj isKindOfClass:[NSNumber class]]) {
    NSDictionary *dict = [self sizeRepresentationForNumber:obj];
    RMFSizeSuffix suffix = [[dict objectForKey:RMFSizeFormatterSuffixKey] intValue];
    NSString *suffixName = [RMFSizeFormatter nameForSuffix:suffix];
    return [NSString stringWithFormat:@"%@ %@", [dict objectForKey:RMFSizeFormatterValueKey], suffixName];
  }
  NSLog(@"%@ Class %@", obj, [obj class]);
  return nil;
}

- (BOOL)getObjectValue:(id *) forString:(NSString *)string errorDescription:(NSString **)error {
  NSScanner *numberScanner = [NSScanner scannerWithString:string];
  double value;
  [numberScanner scanDouble:&value];
  NSString *numberPart = [NSString stringWithFormat:@"%d", value];
  NSString *suffix = 
  
  
  return true;
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

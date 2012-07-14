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
    NSArray *objects = [NSArray arrayWithObjects:@"byte", @"Kb", @"Mb", @"Gb", nil];
    NSArray *keys = [NSArray arrayWithObjects:[NSNumber numberWithInt:0]
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
  while( ( value / 1024.0 ) > 1 ) {
    suffixIndex++;
    value /= 1024.0;
  }
  
  return [RMFSizeFormatter dictForSuffix:suffixIndex andValue:value];
}

+ (NSString *)stringForSizeRepresentation:(NSDictionary *)dict {
  RMFSizeSuffix suffix = [[dict objectForKey:RMFSizeFormatterSuffixKey] intValue];
  NSString *suffixName = [RMFSizeFormatter nameForSuffix:suffix];
  return [NSString stringWithFormat:@"%@ %@", [dict objectForKey:RMFSizeFormatterValueKey], suffixName];
}

- (NSString *)stringForObjectValue:(id)obj {
  if([obj isKindOfClass:[NSNumber class]]) {
    NSDictionary *dict = [RMFSizeFormatter sizeRepresentationForNumber:obj];
    return [RMFSizeFormatter stringForSizeRepresentation:dict];
  }
  NSLog(@"%@ Class %@", obj, [obj class]);
  return nil;
}

+ (RMFSizeSuffix)suffixForString:(NSString *)string {
  BOOL (^filterBlock)(id,NSDictionary*);
  
  filterBlock = ^BOOL(id obj, NSDictionary *bindings){
    NSString *suffixString = obj;
    NSComparisonResult result = [string compare:suffixString options:NSCaseInsensitiveSearch];
    return result == NSOrderedSame;
  };
  
  NSPredicate *predicate = [NSPredicate predicateWithBlock:filterBlock];
  NSArray *matchingSuffix = [[[RMFSizeFormatter suffixNames] allValues] filteredArrayUsingPredicate:predicate];
  
  return [[[RMFSizeFormatter suffixNames] objectForKey:matchingSuffix] intValue]; 
  
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  NSScanner *numberScanner = [NSScanner scannerWithString:string];
  double value;
  BOOL foundDouble = [numberScanner scanDouble:&value];
  if(foundDouble) {
    NSString *suffixPart = [string substringFromIndex:[numberScanner scanLocation]];
    RMFSizeSuffix suffixType = [RMFSizeFormatter suffixForString:suffixPart];
    *anObject = [NSNumber numberWithDouble:(value * pow( 1024.0, (double)suffixType))];
  }
  
  return foundDouble;
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

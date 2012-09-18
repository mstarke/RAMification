//
//  NSString+RMFMenuTools.m
//  RAMification
//
//  Created by michael starke on 18.09.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "NSString+RMFMenuTools.h"

@implementation NSString (RMFMenuTools)

+ (NSString *)stringByAddingDots:(NSString *)aString {
  return [NSString stringWithFormat:@"%@…", aString];
}

@end

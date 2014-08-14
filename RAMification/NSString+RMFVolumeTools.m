//
//  NSString+RMFVolumeTools.m
//  RAMification
//
//  Created by Michael Starke on 11.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "NSString+RMFVolumeTools.h"

@implementation NSString (RMFVolumeTools)


+ (NSString *)uniqueVolumeName:(NSString *)baseName inFolder:(NSString *)path
{
  NSString *uniqueName = baseName;
  NSError *anError = nil;
  NSArray *filePaths= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&anError];
  //TODO: add error handling
  NSMutableSet *files = [NSMutableSet setWithCapacity:[filePaths count]];
  for(NSString* filePath in filePaths)
  {
    [files addObject:[filePath lastPathComponent]];
  }
  
  if([files containsObject:baseName])
  {
    // search for all matching files to our pattern
    NSPredicate *nameMatcher = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [baseName stringByAppendingString:@"_[0-9]+"]];
    [files filterUsingPredicate:nameMatcher];
    NSMutableSet *suffixes = [NSMutableSet setWithCapacity:[files count]];
    
    // gather all the numerical extensions
    for(NSString *filename in files)
    {
      NSString *suffixString = [filename stringByReplacingOccurrencesOfString:[baseName stringByAppendingString:@"_"] withString:@""];
      NSInteger suffix;
      [[NSScanner scannerWithString:suffixString] scanInteger:&suffix];
      [suffixes addObject:@(suffix)];
    }
    // Sort the numbers ascending
    NSArray *descriptor = @[[NSSortDescriptor sortDescriptorWithKey:@"integerValue" ascending:YES]];
    NSArray *sortedSuffixed = [suffixes sortedArrayUsingDescriptors:descriptor];
    // Calculate next number based on biggest found
    // We do not try to fill holes
    NSNumber *maximum = [sortedSuffixed lastObject];
    NSNumber *nextSuffix = @( [maximum integerValue] + 1 );
    
    NSString *newName = [uniqueName stringByAppendingFormat:@"%@_", nextSuffix];
    // release retained old string as we do not need it anymore
    uniqueName = newName;
  }
  return uniqueName;
}

@end

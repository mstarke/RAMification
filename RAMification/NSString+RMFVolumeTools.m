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
  NSArray *filePaths= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
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
      [suffixes addObject:[filename stringByReplacingOccurrencesOfString:[baseName stringByAppendingString:@"_"] withString:@""]];
    }
    
    
    
  }
  
  return uniqueName;
}

- (BOOL)isUsedAsVolumeName
{
  // get all the mounted removable volumes
  NSArray *mountedMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
  NSMutableSet *mountedVolumeNames = [NSMutableSet set];
  // strip the names and just leave the volume name
  for(NSString *path in mountedMedia)
  {
    [mountedVolumeNames addObject:[path lastPathComponent]];
  }
  // return if we are in the array (name based search)
  return [mountedVolumeNames containsObject:self];
}

- (NSString *)volumePath
{
  return [[[NSString alloc] initWithFormat:@"/Volumes/", self] autorelease];
}

@end

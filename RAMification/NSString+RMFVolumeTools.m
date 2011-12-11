//
//  NSString+RMFVolumeTools.m
//  RAMification
//
//  Created by Michael Starke on 11.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "NSString+RMFVolumeTools.h"

@implementation NSString (RMFVolumeTools)

- (BOOL)isUsedAsVolumeName
{
  // get all the mounted removable volumes
  NSArray *mountedMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
  
  // strip the names and just leave the volume name
  for(NSString *path in mountedMedia)
  {
    path = [path lastPathComponent];
  }
  // return if we are in the array (name based search)
  return [mountedMedia containsObject:self];
}

@end

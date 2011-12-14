//
//  NSString+RMFVolumeTools.h
//  RAMification
//
//  Created by Michael Starke on 11.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RMFVolumeTools)

+ (NSString *) uniqueVolumeName:(NSString*)baseName inFolder:(NSString*)path;
- (BOOL) isUsedAsVolumeName;
- (NSString*) volumePath;

@end

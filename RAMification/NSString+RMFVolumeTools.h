//
//  NSString+RMFVolumeTools.h
//  RAMification
//
//  Created by Michael Starke on 11.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RMFVolumeTools)

// This method tries to find a unique name in a path
// If the provided basename is not used, it just return this
// otherwise it generates a name with the style <basename>_<number>
// The number is the first non used number in the names
//
// Example
// 
// Files:   file, file_, file_0, file_00, file_003
// Returns: file_1
+ (NSString *) uniqueVolumeName:(NSString*)baseName inFolder:(NSString*)path;


// Returns YES if the string is used als Volume name
// Returns NO if the string is not used als Volume name.
- (BOOL) isUsedAsVolumeName;

// Returns the Volumepath for a given string?
- (NSString*) volumePath;



@end

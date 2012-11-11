//
//  NSString+RMFVolumeTools.h
//  RAMification
//
//  Created by Michael Starke on 11.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RMFVolumeTools)

/*
 This method tries to find a unique name in a path
 If the provided basename is not used, it just return this
 otherwise it generates a name with the style <basename>_<number>
 The number is the first non used number in the names

 Example
 
 Files:   file, file_, file_0, file_00, file_003
 Returns: file_1
 
 @param baseName name that should be made unique
 @param inFolder folder to search in
 @returns unique filename
 */
+ (NSString *) uniqueVolumeName:(NSString*)baseName inFolder:(NSString*)path;



@end

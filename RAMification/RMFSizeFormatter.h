//
//  RMFSizeFormater.h
//  RAMification
//
//  Created by Michael Starke on 18.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMFSizeFormatter : NSFormatter
/*
 Convenience method for an autoreleased new formatter
 @returns a new autoreleases formatter
 */
+ (instancetype)formatter;

@end

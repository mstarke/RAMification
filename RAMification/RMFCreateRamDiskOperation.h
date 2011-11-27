//
//  NSCreateRamDiskOperation.h
//  RAMification
//
//  Created by Michael Starke on 28.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMFCreateRamDiskOperation : NSOperation

@property (assign) NSUInteger size;
@property (retain) NSString* label;

- (id) initWithSize:(NSUInteger)size andLabel:(NSString*)label;

@end

//
//  RMFBufferDeamon.h
//  RAMification
//
//  Created by michael starke on 06.09.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 
 This Daemon watches for file acitivity on a RAM disk
 and sets the unified buffer cache for all files coresponding to the settings

 */
@interface RMFBufferDeamon : NSObject

@end

//
//  RMFMountController.h
//  RAMification
//
//  Created by Michael Starke on 05.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFRamdisk.h"

@interface RMFMountController : NSObject

- (BOOL) toggleMounted:(RMFRamdisk *)ramdisk;
- (void) volumeAtPath:(NSString *)path wasMounted:(BOOL)mounted;

@end

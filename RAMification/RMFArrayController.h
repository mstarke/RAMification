//
//  RMFArrayController.h
//  RAMification
//
//  Created by michael starke on 08.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "RMFArrayControllerDelegateProtocol.h"

/*
 
 Extended NSArrayController that uses delegates to determine
 canEdit, canRemove and canInsert properties
 
 */
@interface RMFArrayController : NSArrayController

@property (assign) id<RMFArrayControllerDelegateProtocol> delegate;

@end

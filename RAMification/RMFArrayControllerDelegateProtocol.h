//
//  RMFArrayControllerDelegateProtocol.h
//  RAMification
//
//  Created by michael starke on 08.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RMFArrayController;
/*
 Protocoll to conform to when being used as a RMFArrayController Delegate
 */
@protocol RMFArrayControllerDelegateProtocol <NSObject>

@optional
- (BOOL)canRemoveWithArrayController:(RMFArrayController *)arrayController;
- (BOOL)canAddWithArrayController:(RMFArrayController *)arrayController;
- (BOOL)canInsertWithArrayController:(RMFArrayController *)arrayController;

@end

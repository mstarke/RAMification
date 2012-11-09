//
//  RMFLabelTextField.h
//  RAMification
//
//  Created by michael starke on 09.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

APPKIT_EXTERN NSString *const kRMFLabelTextFieldFinderLabelIndexKey;

@interface RMFLabelTextField : NSTextField

@property (nonatomic, assign) NSUInteger finderLabelIndex;

@end

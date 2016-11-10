//
//  RMFFavouriteCellView.h
//  RAMification
//
//  Created by michael starke on 06.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RMFLabelTextField;

APPKIT_EXTERN NSString *const kRMFFavouriteCellViewKeyForIsDefault;

@interface RMFFavouriteCellView : NSTableCellView

@property (weak) IBOutlet RMFLabelTextField *lableTextField;
@property (weak) IBOutlet NSTextField *infoTextField;
@property (nonatomic, assign) BOOL isDefault;

@end

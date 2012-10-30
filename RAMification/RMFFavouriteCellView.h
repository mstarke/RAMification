//
//  RMFFavouriteCellView.h
//  RAMification
//
//  Created by michael starke on 06.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

APPKIT_EXTERN NSString *const kRMFFavouriteCellViewKeyForIsDefault;

@interface RMFFavouriteCellView : NSTableCellView

@property (assign) IBOutlet NSImageView *imageView;
@property (assign) IBOutlet NSTextField *lableTextField;
@property (assign) IBOutlet NSTextField *infoTextField;
@property (nonatomic, retain) NSNumber *isDefault;

@end

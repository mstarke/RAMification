//
//  RMFFavouriteCellView.h
//  RAMification
//
//  Created by michael starke on 06.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RMFFavouriteCellView : NSTableCellView

@property (assign) IBOutlet NSImageView *imageView;
@property (assign) IBOutlet NSTextField *lableTextField;
@property (assign) IBOutlet NSTextField *infoTextField;
@property (nonatomic, assign) NSNumber *isDefault;

@end

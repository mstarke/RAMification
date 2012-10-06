//
//  RMFTableViewDelegate.h
//  RAMification
//
//  Created by Michael Starke on 01.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMFFavouritesTableViewDelegate : NSObject <NSTableViewDelegate>
@property (assign) IBOutlet NSTextField *labelTextField;
@property (assign) IBOutlet NSImageView *iconImageView;
@property (assign) IBOutlet NSTextField *infoTextFiled;

// Creates the popup menu that is dispalyed in the backup mode selection
- (NSMenu *)allocBackupModePopupMenu;

@end

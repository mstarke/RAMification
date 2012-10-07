//
//  RMFPresetSettingsContoller.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsControllerProtocol.h"
#import "RMFFavouritesTableViewDelegate.h"


@interface RMFFavoritesSettingsController : NSViewController <RMFSettingsControllerProtocol> {
  NSDictionary *columIdentifier;
}

@property (retain, readonly) RMFFavouritesTableViewDelegate *tableDelegate;
@property (assign) IBOutlet NSImageView *volumeIconImageView;
@property (assign) IBOutlet NSTableColumn *favouriteColumn;
@property (assign) IBOutlet NSTableView *favouritesTableView;
@property (assign) IBOutlet NSTextField *detailLabelTextField;
@property (assign) IBOutlet NSTextField *detailSizeTextField;
@property (assign) IBOutlet NSPopUpButton *detailBackupPopUp;
@property (assign) IBOutlet NSButton *detailIsAutoMount;

- (IBAction)addPreset:(id)sender;
- (IBAction)deletePreset :(id)sender;

@end

//
//  RMFPresetSettingsContoller.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsTabController.h"
#import "RMFFavouritesTableViewDelegate.h"


@interface RMFFavouritesSettingsController : NSViewController <RMFSettingsTabController> {
  NSDictionary *columIdentifier;
}

@property (retain, readonly) RMFFavouritesTableViewDelegate *tableDelegate;
@property (assign) IBOutlet NSImageView *volumeIconImageView;
@property (assign) IBOutlet NSTableColumn *favouriteColumn;
@property (assign) IBOutlet NSTableView *favouritesTableView;
@property (assign) IBOutlet NSTextField *labelTextField;
@property (assign) IBOutlet NSTextField *sizeTextField;
@property (assign) IBOutlet NSPopUpButton *backupPopUpButton;
@property (assign) IBOutlet NSPopUpButton *labelPopupButton;
@property (assign) IBOutlet NSPopUpButton *actionPopupButton;
@property (assign) IBOutlet NSButton *isAutoMountCheckButton;
@property (assign) IBOutlet NSButton *addRamdiskButton;
@property (assign) IBOutlet NSButton *removeRamdiskButton;
@property (assign) IBOutlet NSImageView *sizeWarningImageView;
@property (retain) IBOutlet NSWindow *iconSelectionWindow;
@property (assign) IBOutlet NSButton *editScriptButton;
@property (assign) IBOutlet NSButton *useMountScriptCheckButton;


- (IBAction)addPreset:(id)sender;
- (IBAction)deletePreset :(id)sender;
- (IBAction)selectVolumeIcon:(id)sender;
- (IBAction)cancelIconSelection:(id)sender;
- (IBAction)finishedIconSelection:(id)sender;
- (IBAction)showScriptEditor:(id)sender;
- (IBAction)toggleUseMountScript:(id)sender;

@end

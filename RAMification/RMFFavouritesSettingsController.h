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

@property (strong, readonly) RMFFavouritesTableViewDelegate *tableDelegate;
@property (weak) IBOutlet NSImageView *volumeIconImageView;
@property (weak) IBOutlet NSTableColumn *favouriteColumn;
@property (weak) IBOutlet NSTableView *favouritesTableView;
@property (weak) IBOutlet NSTextField *labelTextField;
@property (weak) IBOutlet NSTextField *sizeTextField;
@property (weak) IBOutlet NSPopUpButton *backupPopUpButton;
@property (weak) IBOutlet NSPopUpButton *labelPopupButton;
@property (weak) IBOutlet NSPopUpButton *actionPopupButton;
@property (weak) IBOutlet NSButton *isAutoMountCheckButton;
@property (weak) IBOutlet NSButton *addRamdiskButton;
@property (weak) IBOutlet NSButton *removeRamdiskButton;
@property (weak) IBOutlet NSImageView *sizeWarningImageView;
@property (strong) IBOutlet NSWindow *iconSelectionWindow;
@property (weak) IBOutlet NSButton *editScriptButton;
@property (weak) IBOutlet NSButton *useMountScriptCheckButton;


- (IBAction)addPreset:(id)sender;
- (IBAction)deletePreset :(id)sender;
- (IBAction)selectVolumeIcon:(id)sender;
- (IBAction)cancelIconSelection:(id)sender;
- (IBAction)finishedIconSelection:(id)sender;
- (IBAction)showScriptEditor:(id)sender;
- (IBAction)toggleUseMountScript:(id)sender;

@end

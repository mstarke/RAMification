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
  IBOutlet NSTableView* tableView;
  NSDictionary *columIdentifier;
}

@property (retain, readonly) RMFFavouritesTableViewDelegate *tableDelegate;

- (IBAction)addPreset:(id)sender;
- (IBAction)deletePreset :(id)sender;

@end

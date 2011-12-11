//
//  RMFPresetSettingsContoller.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsControllerProtocol.h"
#import "RMFPresetsTableViewDelegate.h"

@interface RMFPresetSettingsController : NSViewController <RMFSettingsControllerProtocol>
{
  IBOutlet NSTableView* tableView;
}

@property (retain, readonly) RMFPresetsTableViewDelegate *tableDelegate;

@end

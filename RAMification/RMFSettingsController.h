//
//  SettingsToolbarDelegate.h
//  RAMification
//
//  Created by Michael Starke on 25.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFGeneralSettingsController.h"
#import "RMFPresetSettingsContoller.h"
#import "RMFSettingsToolbarDelegate.h"

@interface RMFSettingsController : NSObject
{
  NSDictionary *availableSettingsControler;
  RMFSettingsToolbarDelegate *toolbarDelegate;
}

@property (retain) RMFGeneralSettingsController *generalSettingsController;
@property (retain) RMFPresetSettingsContoller *presetSettingsController;
@property (retain) NSToolbar* toolbar;
@property (assign) IBOutlet NSWindow *settingsWindow;

- (void) showSettings: (id)sender;

@end

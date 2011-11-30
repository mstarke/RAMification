//
//  SettingsToolbarDelegate.h
//  RAMification
//
//  Created by Michael Starke on 25.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFGeneralSettingsContoller.h"
#import "RMFPresetSettingsContoller.h"
#import "RMFSettingsToolbarDelegate.h"

enum RMFSettingsTabs {
  RMFGeneralTab,
  RMFPresetsTab,
};


@interface RMFSettingsController : NSObject
{
  NSDictionary *availableSettingsControler;
  RMFSettingsToolbarDelegate *toolbarDelegate;
}

@property (retain) RMFGeneralSettingsContoller *generalSettingsController;
@property (retain) RMFPresetSettingsContoller *presetSettingsController;
@property (retain) NSToolbar* toolbar;
@property (assign) IBOutlet NSWindow *settingsWindow;

- (void) showWindow;
- (void) showWindowWithActiveTab:(NSString *)tabidentifier;

@end

APPKIT_PRIVATE_EXTERN NSString *const RMFGeneralIdentifier;
APPKIT_PRIVATE_EXTERN NSString *const RMFPresetsIdentifier;
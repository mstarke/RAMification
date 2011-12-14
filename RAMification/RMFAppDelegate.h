//
//  AKPAppDelegate.h
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsController.h"
#import "RMFPresetManager.h"
#import "RMFMenuController.h"
#import "RMFMountWatcher.h"

@interface RMFAppDelegate : NSObject <NSApplicationDelegate>

@property (retain) RMFSettingsController *settingsController;
@property (retain) NSMutableDictionary *mountedVolumes;
@property (retain) RMFPresetManager* presetsManager;
@property (readonly) RMFMenuController *menuController;
@property (readonly) RMFMountWatcher *mountWatcher;

@end
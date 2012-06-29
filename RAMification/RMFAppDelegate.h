//
//  AKPAppDelegate.h
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsController.h"
#import "RMFFavoriteManager.h"
#import "RMFMenuController.h"
#import "RMFMountWatcher.h"

@interface RMFAppDelegate : NSObject <NSApplicationDelegate>

@property (retain, readonly) RMFSettingsController *settingsController;
@property (retain, readonly) RMFFavoriteManager* favoritesManager;
@property (retain, readonly) RMFMenuController *menuController;
@property (retain, readonly) RMFMountWatcher *mountWatcher;

@end
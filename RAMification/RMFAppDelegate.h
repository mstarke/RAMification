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

@property (retain) RMFSettingsController *settingsController;
@property (retain) RMFFavoriteManager* favoritesManager;
@property (readonly) RMFMenuController *menuController;
@property (readonly) RMFMountWatcher *mountWatcher;

@end
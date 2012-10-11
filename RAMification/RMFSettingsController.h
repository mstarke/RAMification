//
//  SettingsToolbarDelegate.h
//  RAMification
//
//  Created by Michael Starke on 25.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFGeneralSettingsController.h"
#import "RMFFavouritesSettingsController.h"

@interface RMFSettingsController : NSObject <NSToolbarDelegate>

@property (readonly) NSUInteger hibernateMode;
@property (assign) IBOutlet NSWindow *settingsWindow;

+ (RMFSettingsController *)sharedController;

- (void) showSettings: (id)sender;

@end

//
//  AKPAppDelegate.h
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SettingsToolbarDelegate.h"
@interface AKPAppDelegate : NSObject <NSApplicationDelegate>
{
  SettingsToolbarDelegate *toolbarDelegate;
}

@property (assign) IBOutlet NSWindow *settingsWindow;
@property (assign) IBOutlet NSToolbar *settingsToolbar;
@property (retain) NSStatusItem *statusItem;
@property (retain) NSMenu *menu;
@property (assign, readonly) NSUInteger ramdisksize;
@property (retain, readonly) NSString *ramdiskname;

- (void) createStatusItem;
- (void) createMenu;
- (void) quitApplication;
- (void) createRamdisk;
- (void) removeRamdisk;
- (void) showSettings;

@end

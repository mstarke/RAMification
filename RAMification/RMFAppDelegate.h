//
//  AKPAppDelegate.h
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsController.h"

@interface RMFAppDelegate : NSObject <NSApplicationDelegate>
{
  @private
  NSOperationQueue *queue;
}
@property (retain) NSStatusItem *statusItem;
@property (retain) NSMenu *menu;
@property (assign) NSUInteger ramdisksize;
@property (retain) NSString *ramdiskname;
@property (retain) RMFSettingsController *settingsController;

- (void) createStatusItem;
- (void) createMenu;
- (void) quitApplication;
- (void) createRamdisk;
- (void) removeRamdisk;
- (void) showSettings;
- (void) showSettingsTab:(id)sender;

@end
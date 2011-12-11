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

@interface RMFAppDelegate : NSObject <NSApplicationDelegate>
{
  @private
  NSOperationQueue *queue;
}

@property (retain) NSStatusItem *statusItem;
@property (retain) NSMenu *menu;
@property (retain) RMFSettingsController *settingsController;
@property (retain) NSMutableDictionary *mountedVolumes;
@property (retain, readonly) NSMenu *presetsSubMenu;
@property (retain) RMFPresetManager* presetsManager;


- (void) createStatusItem;
- (void) createMenu;
- (void) quitApplication;
- (void) mountRamdisk:(RMFVolumePreset *)preset;
- (void) removeRamdisk;
- (void) showSettingsTab:(id)sender;
- (void) updatePresetsMenu;

@end
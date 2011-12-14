//
//  RMFMenuController.h
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFVolumePreset.h"

@interface RMFMenuController : NSObject
{
  @private
  NSMenu *menu;
  NSMenu *presetsMenu;
  NSStatusItem *statusItem;
  NSOperationQueue *queue;
  NSMutableDictionary *presetMap;
  
}



- (void) createStatusItem;
- (void) createMenu;
- (void) createPresetsMenu;
- (void) updatePresetsMenu;
- (void) quitApplication;
- (void) mount:(RMFVolumePreset*) preset;
- (void) eject:(RMFVolumePreset*) preset;

- (void) removeRamdisk;
- (void) showSettingsTab:(id)sender;
- (void) updatePresetState:(id)sender;

@end

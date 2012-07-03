//
//  RMFMenuController.h
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFRamdisk.h"

@interface RMFMenuController : NSObject
{
  @private
  NSMenu *menu;
  NSMenu *favoritesMenu;
  NSStatusItem *statusItem;
  NSOperationQueue *queue;
  NSMutableDictionary *favouritesToMenuItemsMap;
  
}

- (void) quitApplication;
- (void) mount:(RMFRamdisk*) preset;
- (void) eject:(RMFRamdisk*) preset;

- (void) removeRamdisk;
- (void) showSettingsTab:(id)sender;

@end

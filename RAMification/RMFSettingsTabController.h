//
//  RMFSettingsControllerProtocol.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Protocoll for Settings controller that can be added in the Settings window
 */
@protocol RMFSettingsTabController <NSObject>

@required
// Unique identifier for the settings controller
+ (NSString*) identifier;
// Label for the settings tab (is used in the toolbar item by the controller itself)
+ (NSString*) label;
// item to be placed in the Toolbar
+ (NSToolbarItem*) toolbarItem;

@end

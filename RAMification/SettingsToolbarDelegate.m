//
//  SettingsToolbarDelegate.m
//  RAMification
//
//  Created by Michael Starke on 25.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "SettingsToolbarDelegate.h"


@implementation SettingsToolbarDelegate

- (NSArray*) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
  return [NSArray arrayWithObjects:RMFGeneral, RMFPresets, nil];
}

NSString *const RMFGeneral = @"General";
NSString *const RMFPresets = @"Presets";

@end

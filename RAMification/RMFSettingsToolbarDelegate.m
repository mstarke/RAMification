//
//  RMFSettingsToolbarDelegate.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSettingsToolbarDelegate.h"
#import "RMFGeneralSettingsContoller.h"
#import "RMFPresetSettingsContoller.h"
#import "RMFSettingsControllerProtocol.h"

@implementation RMFSettingsToolbarDelegate

- (id)init
{
  self = [super init];
  if (self)
  {
    controllerMap = [NSDictionary dictionaryWithObjectsAndKeys:[RMFGeneralSettingsContoller class], [RMFGeneralSettingsContoller identifier],
                                                                [RMFPresetSettingsContoller class], [RMFPresetSettingsContoller identifier], nil];
  }
  return self;
}

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
  return [controllerMap allKeys];
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
  return [controllerMap allKeys];
}

- (NSArray *) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
  return [controllerMap allKeys];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
  return [[controllerMap objectForKey:itemIdentifier] toolbarItem];
}
@end

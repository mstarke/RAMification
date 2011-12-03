//
//  RMFDefaultSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFGeneralSettingsController.h"
#import "RMFAppDelegate.h"

@implementation RMFGeneralSettingsController

+ (NSString *) identifier
{
  return @"GeneralSettings";
}

+ (NSString *) label
{
  return NSLocalizedString(@"GENERAL_SETTINGS_LABEL", @"Label for the General Settings");
}

+ (NSToolbarItem *) toolbarItem
{
  NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:[RMFGeneralSettingsController identifier]];
  [item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
  id delegate = [NSApp delegate];
  [item setTarget:((RMFAppDelegate*)delegate).settingsController];
  [item setAction:@selector(showSettings:)];
  return [item autorelease];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:@"GeneralSettings" bundle:[NSBundle mainBundle]];
  if (self)
  {
    // init
  }
    
    return self;
}


@end

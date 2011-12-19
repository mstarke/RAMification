//
//  RMFDefaultSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFGeneralSettingsController.h"
#import "RMFAppDelegate.h"
#import "RMFSettingsKeys.h"

@implementation RMFGeneralSettingsController


#pragma mark RMFSettingsController Protocol

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
  [item setAction:@selector(showSettings:)];
  [item setLabel:[RMFGeneralSettingsController label]];
  return [item autorelease];
}

#pragma mark object lifecylce

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:@"GeneralPane" bundle:[NSBundle mainBundle]];
  if (self)
  {
    // init
  }
    
    return self;
}

#pragma mark viewLoad overrides
- (void)loadView
{
  [super loadView];
  [self didLoadView];
}

- (void)didLoadView
{
  // Set up the bindings for the Interface
  
  // label
  NSString * keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyLabel];
  [label bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  
  // size
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeySize];
  [size bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  [sizeStepper bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  [sizeStepper setMaxValue:1000000000];
  [sizeStepper setMinValue:1048];
  [sizeStepper setIncrement:1048];
  
  // backup interval
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyBackupInterval];
  [backupInterval bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  [backupIntervalStepper bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  [backupIntervalStepper setMinValue:60];
  [backupIntervalStepper setMaxValue:100000000000000];
  [backupIntervalStepper setIncrement:60];
  
}


#pragma mark actions

- (IBAction)setBackupInterval:(id)sender
{

}

@end

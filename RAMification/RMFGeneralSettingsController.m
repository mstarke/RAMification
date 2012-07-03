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

const NSUInteger MinimumBackupInterval = 15;      // 15s
const NSUInteger MaxiumumBackupInterval = 86400;  // 24h 
const NSUInteger BackupdIntervalStepSize = 15;    // 15s
const NSUInteger MinumumRamdiskSize = 1024;       // 1Mb
const NSUInteger MaxiumumRamdiskSize = 33554432;  // 32Gb
const NSUInteger RamdiskSizeStepSize = 1024;      // 1Mb


@interface RMFGeneralSettingsController ()

- (void) checkHibernationMode;

@end

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
  //[self.warningIcon setImage:[NSImage imageNamed:NSImageNameCaution]];
 
  // label
  NSString * keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyLabel];
  [label bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  // size
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeySize];
  [size bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  [sizeStepper setMaxValue:1000000000];
  [sizeStepper setMinValue:1048];
  [sizeStepper setIncrement:1048];
  [sizeStepper bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];

  // backup interval
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyBackupInterval];
  [backupInterval bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  [backupIntervalStepper setMinValue:60];
  [backupIntervalStepper setMaxValue:100000000000000];
  [backupIntervalStepper setIncrement:60];
  [backupIntervalStepper bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
}

- (void) checkHibernationMode
{
  // run schell command pmset -g | grep hibernamemode
  // check for mode
  // or look for cocoa api to get this data
}


#pragma mark actions

- (IBAction)setBackupInterval:(id)sender
{

}

@end

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
- (void)didLoadView;

@end

@implementation RMFGeneralSettingsController

@synthesize labelInput = _label;
@synthesize sizeInput = _size;
@synthesize backupIntervalInput = _backupInterval;
@synthesize sizeStepper = _sizeStepper;
@synthesize backupIntervalStepper = _backupIntervalStepper;

#pragma mark RMFSettingsController Protocol

+ (NSString *) identifier {
  return @"GeneralSettings";
}

+ (NSString *) label {
  return NSLocalizedString(@"GENERAL_SETTINGS_LABEL", @"Label for the General Settings");
}

+ (NSToolbarItem *) toolbarItem {
  NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:[RMFGeneralSettingsController identifier]];
  [item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
  [item setAction:@selector(showSettings:)];
  [item setLabel:[RMFGeneralSettingsController label]];
  return [item autorelease];
}

#pragma mark object lifecylce

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:@"GeneralPane" bundle:[NSBundle mainBundle]];
  if (self) {
    // init
  } 
  return self;
}

#pragma mark viewLoad overrides
- (void)loadView {
  [super loadView];
  [self didLoadView];
}

- (void)didLoadView {
  // Set up the bindings for the Interface
  //[self.warningIcon setImage:[NSImage imageNamed:NSImageNameCaution]];
  
  // label
  NSString * keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyLabel];
  [self.labelInput bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  // size
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeySize];
  [self.sizeInput bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  [self.sizeStepper setMaxValue:1000000000];
  [self.sizeStepper setMinValue:1048];
  [self.sizeStepper setIncrement:1048];
  [self.sizeStepper bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  // backup interval
  NSDictionary *bindinOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"Something missing", NSNullPlaceholderBindingOption, nil];
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyBackupInterval];
  [self.backupIntervalInput bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:bindinOptions];
  [self.backupIntervalStepper setMinValue:60];
  [self.backupIntervalStepper setMaxValue:100000000000000];
  [self.backupIntervalStepper setIncrement:60];
  [self.backupIntervalStepper bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
}

- (void) checkHibernationMode {
  // run shell command pmset -g | grep hibernamemode
  // check for mode
  // or look for cocoa api to get this data
}

@end

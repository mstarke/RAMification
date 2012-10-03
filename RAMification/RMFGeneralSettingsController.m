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
#import "RMFSizeFormatter.h"
#import "RMFSettingsController.h"

const NSUInteger MinimumBackupInterval = 15;      // 15s
const NSUInteger MaxiumumBackupInterval = 86400;  // 24h 
const NSUInteger BackupdIntervalStepSize = 15;    // 15s
const NSUInteger MinumumRamdiskSize = 1024;       // 1Mb
const NSUInteger MaxiumumRamdiskSize = 33554432;  // 32Gb
const NSUInteger RamdiskSizeStepSize = 1024;      // 1Mb

@interface RMFGeneralSettingsController ()

- (void)didLoadView;
- (void)setBackupInterval:(id)sender;
- (NSString *)memoryInfoText;

@end

@implementation RMFGeneralSettingsController

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
    NSLog(@"Created %@", [self class]);
  } 
  return self;
}
#pragma mark getter/setter

#pragma mark viewLoad overrides
- (void)loadView {
  [super loadView];
  [self didLoadView];
}

- (void)didLoadView {
  // Setup correct names
  NSString *template = NSLocalizedString(@"GENERAL_SETTINNGS_LAUNCH_AT_LOGIN_LABEL", @"Label for the launch at login button. Insert 1 object placeholder");
  RMFAppDelegate *delegate = [NSApp delegate];
  [self.startAtLoginCheckButton setTitle:[NSString stringWithFormat:template, [delegate executabelName]]];
  
  [self.sizeInfo setStringValue:[self memoryInfoText]];
  [self.sizeInfo sizeToFit];
  
  // attach the number formatter to the size label
  [self.sizeInput setFormatter:[RMFSizeFormatter formatter]];
  
  // Set up the bindings for the Interface
  // label
  NSString * keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyLabel];
  [self.labelInput bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  // size
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeySize];
  [self.sizeInput bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  // backup interval
  NSDictionary *bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"Something missing", NSNullPlaceholderBindingOption, nil];
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyBackupInterval];
//  [self.backupIntervalInput bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:bindingOptions];
//  [self.backupIntervalStepper setMinValue:60];
//  [self.backupIntervalStepper setMaxValue:100000000000000];
//  [self.backupIntervalStepper setIncrement:60];
//  [self.backupIntervalStepper bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  [self.sizeStepper setMinValue:0];
  [self.sizeStepper setMaxValue:10];
  [self.sizeStepper setIncrement:1];
  //[self.sizeStepper bind:@"value" toObject:self withKeyPath:@"sizeBridgeValue" options:nil];
  keypath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyDisableUnifiedBuffer];
  [self.isBufferDisabled bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keypath options:nil];
  
  
  BOOL shouldHide = (0 != [[RMFSettingsController sharedController] hibernateMode]);
  [self.hibernateWarning setHidden:shouldHide];
  
  // Generate Popup Menu
  NSMenu *backupMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  NSArray *actionArray = @[ @"every 30 seconds", @"every minute", @"every 30 minutes", @"every hour" ];
  NSArray *backupIntervals = @[ @30, @60, @1800, @3600 ];
  for(NSString *label in actionArray) {
    NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:label action:@selector(setBackupInterval:) keyEquivalent:@""];
    NSUInteger index = [actionArray indexOfObject:label];
    [menuItem setRepresentedObject:[backupIntervals objectAtIndex:index]];
    [menuItem setTarget:self];
    [backupMenu addItem:menuItem];
    [menuItem release];
  }
  NSUInteger currentInterval = [[[NSUserDefaults standardUserDefaults] valueForKey:RMFSettingsKeyBackupInterval] integerValue];
  NSNumber *interval = @(currentInterval);
  NSUInteger currentIndex = [backupIntervals indexOfObject:interval];
  if(NSNotFound == currentIndex) {
    currentIndex = 0;
  }
  [self.backupIntervalPopUp setMenu:backupMenu];
  [self.backupIntervalPopUp selectItemAtIndex:currentIndex]; 
}

- (NSString *)memoryInfoText {
  unsigned long long systemMemory = [[NSProcessInfo processInfo] physicalMemory];
  NSString *warningTemplate = NSLocalizedString(@"GENERAL_SETTINNGS_MAXIUMUM_SIZE", @"Label for the maxiumum size for a ramdisk. Insert 1 object placeholder" );
  // Get the system memory and calculate the Gb theoretical maxium RAM disk size
  // The disk is 2 times the storage as it's ram bufferd.
  // 1024 * 1024 * 1024 * 2 = 2147483648
  return [NSString stringWithFormat:warningTemplate, ( systemMemory / ( 2147483648 ) ) ];
}

- (void)setBackupInterval:(id)sender {
  if([sender isMemberOfClass:[NSMenuItem class]]) {
    NSMenuItem *menuItem = sender;
    NSNumber *number = [menuItem representedObject];
    NSLog(@"Interval changed to %@ Seconds", number);
    [[NSUserDefaults standardUserDefaults] setInteger:[number integerValue] forKey:RMFSettingsKeyBackupInterval];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}
@end

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

const NSUInteger MinumumRamdiskSize = 512*1024;       // 1KB

@interface RMFGeneralSettingsController ()


@property (assign) IBOutlet NSButton *startAtLoginCheckButton;
@property (assign) IBOutlet NSButton *backupTrashcanCheckbox;
@property (assign) IBOutlet NSPopUpButton *backupIntervalPopUp;
@property (assign) IBOutlet NSTextField *hibernateWarning;
@property (assign) IBOutlet NSButton *bufferDisabledCheckBox;
@property (assign) IBOutlet NSButton *unmountOnQuitCheckbox;
@property (assign) IBOutlet NSButton *disableSpotlightCheckBox;


- (void)didLoadView;
- (void)selectionChanged:(id)sender;

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
  NSString *template = NSLocalizedString(@"GENERAL_SETTINGS_LAUNCH_AT_LOGIN_LABEL", @"Label for the launch at login button. Insert 1 object placeholder");
  RMFAppDelegate *delegate = [NSApp delegate];
  [self.startAtLoginCheckButton setTitle:[NSString stringWithFormat:template, [delegate executabelName]]];
  
  // Bindings
  NSString *disableBufferKeypath = [NSString stringWithFormat:@"values.%@", kRMFSettingsKeyDisableUnifiedBuffer];
  NSString *unmountOnQuitKeypath = [NSString stringWithFormat:@"values.%@", kRMFSettingsKeyUnmountOnQuit];
  NSString *backupTrashcanKeypath = [NSString stringWithFormat:@"values.%@", kRMFSettingsKeyBackupTrashcan];
  NSString *disableSpotlightKeypath = [NSString stringWithFormat:@"values.%@", kRMFSettingsKeyDisableSpotlight];
  
  NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  
  [self.bufferDisabledCheckBox bind:NSValueBinding toObject:defaultsController withKeyPath:disableBufferKeypath options:nil];
  [self.unmountOnQuitCheckbox bind:NSValueBinding toObject:defaultsController withKeyPath:unmountOnQuitKeypath options:nil];
  [self.backupTrashcanCheckbox bind:NSValueBinding toObject:defaultsController withKeyPath:backupTrashcanKeypath options:nil];
  [self.disableSpotlightCheckBox bind:NSValueBinding toObject:defaultsController withKeyPath:disableSpotlightKeypath options:nil];
  
  BOOL shouldHide = (0 != [[RMFSettingsController sharedController] hibernateMode]);
  [self.hibernateWarning setHidden:shouldHide];
  
  // Generate Popup Menu
  NSMenu *backupMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  NSString *backupEachHalfMinute = NSLocalizedString(@"GENERAL_SETTINGS_BACKUP_EVERY_30_SECONDS", @"Backup every 30 seconds");
  NSString *backupEachMinute = NSLocalizedString(@"GENERAL_SETTINGS_BACKUP_EVERY_MINUTE", @"Backup every minute");
  NSString *backupEachHalfHour = NSLocalizedString(@"GENERAL_SETTINGS_BACKUP_EVERY_30_MINUTES", @"Backup every 30 minutes");
  NSString *backupEachHour = NSLocalizedString(@"GENERAL_SETTINGS_BACKUP_EVERY_HOUR", @"Backup every hour");
  NSArray *actionArray = @[ backupEachHalfMinute, backupEachMinute, backupEachHalfHour, backupEachHour ];
  NSArray *backupIntervals = @[ @30, @60, @1800, @3600 ];
  for(NSString *label in actionArray) {
    NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:label action:nil keyEquivalent:@""];
    NSUInteger index = [actionArray indexOfObject:label];
    [menuItem setRepresentedObject:[backupIntervals objectAtIndex:index]];
    [menuItem setTarget:self];
    [backupMenu addItem:menuItem];
    [menuItem release];
  }
  NSUInteger currentInterval = [[[NSUserDefaults standardUserDefaults] valueForKey:kRMFSettingsKeyBackupInterval] integerValue];
  NSNumber *interval = @(currentInterval);
  NSUInteger currentIndex = [backupIntervals indexOfObject:interval];
  if(NSNotFound == currentIndex) {
    currentIndex = 0;
  }
  [self.backupIntervalPopUp setMenu:backupMenu];
  [self.backupIntervalPopUp selectItemAtIndex:currentIndex];
  [backupMenu release];
}

- (void)selectionChanged:(id)sender {
  if(![sender isMemberOfClass:[NSPopUpButton class]]) {
    return; // wrong sender, ignore
  }
  NSMenuItem *menuItem = [self.backupIntervalPopUp selectedItem];
  NSNumber *number = [menuItem representedObject];
  NSLog(@"Interval changed to %@ Seconds", number);
  [[NSUserDefaults standardUserDefaults] setInteger:[number integerValue] forKey:kRMFSettingsKeyBackupInterval];
  [[NSUserDefaults standardUserDefaults] synchronize];
}
@end

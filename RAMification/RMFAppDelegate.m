//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFAppDelegate.h"
#import "RMFCreateRamDiskOperation.h"
#import "RMFVolumePreset.h"

// predefined values (private)
NSString *const RMFMenuIconTemplateImage = @"MenuItemIconTemplate"; 

// actual implemenation

@implementation RMFAppDelegate

@synthesize statusItem = _statusItem;
@synthesize settingsController = _settingsController;
@synthesize menu = _menu;
@synthesize mountedVolumes = _mountedVolumes;
@synthesize presets = _presets;

+ (void) initialize
{
  NSURL *defaultsPlistURL = [[NSBundle mainBundle] URLForResource:@"Defaults" withExtension:@"plist"];
  if(defaultsPlistURL != nil)
  {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:defaultsPlistURL]];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)dealloc
{
  self.statusItem  = nil;
  self.settingsController = nil;
  self.menu = nil;
  self.mountedVolumes = nil;
  
  [super dealloc];
  // remove the toolbardelegate from the 
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // intialize settings window toolbar delegate
  queue = [[NSOperationQueue alloc] init];
    
  [self createMenu];
  [self createStatusItem];
}


- (void) createMenu
{
  _menu = [[NSMenu alloc] initWithTitle:@"menu"];
  // Create ramdisk
  NSMenuItem *item;
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Create Ramdisk" action:@selector(createRamdisk) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [self.menu addItem:item];
  [item release];
  
  // Destroy ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Destroy Ramdisk" action:@selector(removeRamdisk) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [self.menu addItem:item];
  [item release];

  // Separation
  [self.menu addItem:[NSMenuItem separatorItem]];

  NSMenu *presetsSubMenu = [[NSMenu alloc] initWithTitle:@"PresetsSubmenu"];
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Manage Presets..." action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFPresetSettingsController identifier]];
  [item setEnabled:YES];
  [item setTarget:self];
  [presetsSubMenu addItem:item];
  [item release];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Presets" action:nil keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [item setSubmenu:presetsSubMenu];
  [self.menu addItem:item];
  [presetsSubMenu release];
  [item release];
  

  
  // Separation
  [self.menu addItem:[NSMenuItem separatorItem]];

  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Preferences..." action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFGeneralSettingsController identifier]];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [self.menu addItem:item];
  [item release];

  // Separation
  [self.menu addItem:[NSMenuItem separatorItem]];
  
  // Quit
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Quit" action:@selector(quitApplication) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [self.menu addItem:item];
  [item release];
}

- (void) createStatusItem
{
  NSStatusBar *bar = [NSStatusBar systemStatusBar];
  self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
  NSImage *menuIconImage = [NSImage imageNamed:RMFMenuIconTemplateImage];
  [self.statusItem setImage:menuIconImage];
  [self.statusItem setEnabled:YES];
  [self.statusItem setHighlightMode:YES];
  [self.statusItem setMenu:self.menu];
}

- (void) quitApplication
{
  //Unmount ramdisk?
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) showSettingsTab:(id)sender
{
  if(self.settingsController == nil)
  {
   _settingsController = [[RMFSettingsController alloc] init];
  }
  
  [self.settingsController showSettings:[sender representedObject]];
}

- (void) createRamdisk
{
  RMFCreateRamDiskOperation *mountOperation = [[RMFCreateRamDiskOperation alloc] init];
  [queue cancelAllOperations];
  [queue addOperation:mountOperation];
  [mountOperation release];
}

- (void) removeRamdisk
{
  [queue cancelAllOperations];
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
}

@end

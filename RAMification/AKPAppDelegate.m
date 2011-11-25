//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "AKPAppDelegate.h"

@implementation AKPAppDelegate

@synthesize settingsWindow = _window;
@synthesize settingsToolbar = _settingsToolbar;
@synthesize statusItem = _statusItem;
@synthesize menu = _menu;
@synthesize ramdiskname = _ramdiskname;
@synthesize ramdisksize = _ramdisksize;

- (void)dealloc
{
  [super dealloc];
  // remove the toolbardelegate from the 
  [self.settingsToolbar setDelegate:nil];
  [toolbarDelegate release];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // intialize settings window toolbar delegate
  toolbarDelegate = [[SettingsToolbarDelegate alloc] init];
  [self.settingsToolbar setDelegate:toolbarDelegate];
  NSLog([[self.settingsToolbar delegate] description]);
  [self createMenu];
  [self createStatusItem];
}

- (void) createMenu
{
  self.menu = [[NSMenu alloc] initWithTitle:@"menu"];
  // Create ramdisk
  NSMenuItem *item;
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Create Ramdisk" action:@selector(createRamdisk) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [self.menu addItem:item];
  
  // Destroy ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Destroy Ramdisk" action:@selector(removeRamdisk) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [self.menu addItem:item];

  // Separation
  [self.menu addItem:[NSMenuItem separatorItem]];

  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Manage Presets..." action:@selector(showSettings) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [self.menu addItem:item];

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
  //[self.statusItem setTitle:@"RAMification"];
  [self.statusItem setImage: [NSImage imageNamed:NSImageNameActionTemplate]];
  [self.statusItem setEnabled:YES];
  [self.statusItem setHighlightMode:YES];
  [self.statusItem setMenu:self.menu];
}

- (void) quitApplication
{
  //Unmount ramdisk?
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) showSettings
{
  [self.settingsWindow setIsVisible:YES];
}

- (void) createRamdisk
{
  // test if disk is mounted
  // create the device
  // hdiutil attach -nomount ram://MB*2048 
  // and format it
  // diskutil erasevolume HFS+ <NAME> <DEVICE>
  //diskutil erasevolume HFS+ "ramdisk" `hdiutil attach -nomount ram://MB*2048`
}

- (void) removeRamdisk
{
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
}

@end

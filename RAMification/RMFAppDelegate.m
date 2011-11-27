//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFAppDelegate.h"

// predefined values (private)
NSString *const defaultName = @"Ramdisk";
const NSUInteger defaultSize = 1024;

// actual implemenation

@implementation RMFAppDelegate

@synthesize statusItem = _statusItem;
@synthesize settingsController = _toolbarController;
@synthesize menu = _menu;
@synthesize ramdiskname = _ramdiskname;
@synthesize ramdisksize = _ramdisksize;

- (void)dealloc
{
  [super dealloc];
  // remove the toolbardelegate from the 
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // intialize settings window toolbar delegate
  [self createMenu];
  [self createStatusItem];
  
  self.ramdiskname = defaultName;
  self.ramdisksize = defaultSize;
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
  if(self.settingsController == nil)
  {
    self.settingsController = [[RMFSettingsController alloc] init];
  }
  [self.settingsController showWindow];
}

- (void) createRamdisk
{
  // TODO test if disk is mounted
  NSPipe *output = [NSPipe pipe];  
  NSTask *createDisk = [[NSTask alloc] init];
  
  // create the device
  // hdiutil attach -nomount ram://MB*2048
  
  // create the string for the desired ramdisksize
  NSString *ramdisksize = [NSString stringWithFormat:@"ram://%d", self.ramdisksize*2048];
  
  // create the task and run it
  [createDisk setLaunchPath:@"/usr/bin/hdiutil"];
  [createDisk setArguments:[NSArray arrayWithObjects:@"attach", @"-nomount", ramdisksize, nil]];
  [createDisk setStandardOutput:output];
  [createDisk launch];
  
  
  // retrieve the device name
  NSFileHandle *outputFileHandle = [output fileHandleForReading];
  NSString *deviceName = [[NSString alloc] initWithData:[outputFileHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
  NSString *strippedDeviceName = [deviceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [deviceName release];
  [createDisk release];
  
  // and format it
  // diskutil erasevolume HFS+ <NAME> <DEVICE>
  createDisk = [[NSTask alloc] init];
  [createDisk setLaunchPath:@"/usr/sbin/diskutil"];
  [createDisk setArguments:[NSArray arrayWithObjects:@"erasevolume", @"HFS+", self.ramdiskname, strippedDeviceName, nil]];
  [createDisk launch];
  [createDisk release];

  //diskutil erasevolume HFS+ "ramdisk" `hdiutil attach -nomount ram://MB*2048`
}

- (void) removeRamdisk
{
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
}

@end

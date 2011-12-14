//
//  RMFMenuController.m
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFMenuController.h"
#import "RMFVolumePreset.h"
#import "RMFPresetManager.h"
#import "RMFAppDelegate.h"
#import "RMFCreateRamDiskOperation.h"
#import "NSString+RMFVolumeTools.h"

NSString *const RMFMenuIconTemplateImage = @"MenuItemIconTemplate"; 

@implementation RMFMenuController

#pragma mark object lifecycle
- (id)init
{
  self = [super init];
  if (self)
  {
    queue = [[NSOperationQueue alloc] init];
    presetMap = [[NSMutableDictionary alloc] init];
    [self createMenu];
    [self createStatusItem];
  }
  return self;
}

- (void)dealloc {
  [queue release];
  [statusItem release];
  [menu release];
  [presetMap release];
  
  queue = nil;
  statusItem = nil;
  menu = nil;
  presetMap = nil;
  
  [super dealloc];
}

# pragma mark create/update menu

- (void)createPresetsMenu
{
  NSMenuItem *item;
  RMFPresetManager *presetsManager = ((RMFAppDelegate*)[NSApp delegate]).presetsManager;
  presetsMenu = [[NSMenu alloc] initWithTitle:@"PresetsSubmenu"];
  
  for(RMFVolumePreset *preset in presetsManager.presets)
  {
    item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:preset.volumeLabel action:@selector(updatePresetState:) keyEquivalent:@""];
    //[item setState:NSMixedState];
    [item setTarget:self];
    [presetsMenu addItem:item];
    [presetMap setObject:preset forKey:[NSValue valueWithPointer:item]];
    [preset addObserver:self forKeyPath:@"isMounted" options:0 context:nil];
    [item release];
  }
  
  if([presetsManager.presets count] == 0)
  {
    item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"No Presets defined" action:nil keyEquivalent:@""];
    [presetsMenu addItem:item];
    [item release];
  }
  
  [presetsMenu addItem:[NSMenuItem separatorItem]];
}

- (void) createMenu
{
  menu = [[NSMenu alloc] initWithTitle:@"menu"];
  // Create ramdisk
  NSMenuItem *item;
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Create Ramdisk" action:@selector(updatePresetState:) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [menu addItem:item];
  [item release];
  
  // Destroy ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Destroy Ramdisk" action:@selector(removeRamdisk) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [menu addItem:item];
  [item release];
  
  // Separation
  [menu addItem:[NSMenuItem separatorItem]];
  
  [self createPresetsMenu];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Manage Presets..." action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFPresetSettingsController identifier]];
  [item setEnabled:YES];
  [item setTarget:self];
  [presetsMenu addItem:item];
  [item release];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Presets" action:nil keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [item setSubmenu:presetsMenu];
  [menu addItem:item];
  [item release];
  
  // Separation
  [menu addItem:[NSMenuItem separatorItem]];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Preferences..." action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFGeneralSettingsController identifier]];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [menu addItem:item];
  [item release];
  
  // Separation
  [menu addItem:[NSMenuItem separatorItem]];
  
  // Quit
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Quit" action:@selector(quitApplication) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [menu addItem:item];
  [item release];
}

- (void) createStatusItem
{
  NSStatusBar *bar = [NSStatusBar systemStatusBar];
  statusItem = [[bar statusItemWithLength:NSVariableStatusItemLength] retain];
  NSImage *menuIconImage = [NSImage imageNamed:RMFMenuIconTemplateImage];
  [statusItem setImage:menuIconImage];
  [statusItem setEnabled:YES];
  [statusItem setHighlightMode:YES];
  [statusItem setMenu:menu];
}

- (void)updatePresetsMenu
{
  for(NSMenuItem *item in [presetsMenu itemArray])
  {
    RMFVolumePreset *preset = [presetMap objectForKey:[NSValue valueWithPointer:item]];
    if(preset != nil)
    {
      if(preset.isMounted)
      {
        [item setState:NSOnState];
      }
      else
      {
        [item setState:NSOffState];
      }
    }
  }
}


# pragma mark actions

- (void) quitApplication
{
  //Unmount ramdisk?
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) showSettingsTab:(id)sender
{
  [((RMFAppDelegate*)[NSApp delegate]).settingsController showSettings:[sender representedObject]];
}

- (void)updatePresetState:(id)sender
{
  NSMenuItem* item = sender;
  RMFVolumePreset* itemPreset = [[presetMap objectForKey:[NSValue valueWithPointer:item]] retain];
  if(itemPreset.isMounted)
  {
    [self eject:itemPreset];
  }
  else
  {
    [self mount:itemPreset];
  }
  [itemPreset release];
}

# pragma mark mount/unmount

- (void) mount:(RMFVolumePreset*) preset
{
  RMFCreateRamDiskOperation *mountOperation = [[RMFCreateRamDiskOperation alloc] initWithPreset:preset];
  [queue cancelAllOperations];
  [queue addOperation:mountOperation];
  [mountOperation release];
}

- (void)eject:(RMFVolumePreset *)preset
{
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[preset.volumeLabel volumePath]];
}

- (void) removeRamdisk
{
  [queue cancelAllOperations];
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if([object isMemberOfClass:[RMFVolumePreset class]])
  {
    [self updatePresetsMenu];
  }
}

@end

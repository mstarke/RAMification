//
//  RMFPresetSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFPresetSettingsController.h"
#import "RMFVolumePreset.h"
#import "RMFAppDelegate.h"

@implementation RMFPresetSettingsController

@synthesize tableDelegate = _tableDelegate;

+ (NSString *) identifier
{
  return @"PresetSettings";
}

+ (NSString *) label
{
  return NSLocalizedString(@"PRESET_SETTINGS_LABEL", @"Label for the Preset Settings");
}

+ (NSToolbarItem *) toolbarItem
{
  NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:[RMFPresetSettingsController identifier]];
  [item setImage:[NSImage imageNamed:NSImageNameFolderSmart]];
  [item setLabel:[RMFPresetSettingsController label]];
  [item setAction:@selector(showSettings:)];
  return [item autorelease];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:@"PresetsPane" bundle:[NSBundle mainBundle]];
  if (self)
  {
    columIdentifier = [NSDictionary dictionaryWithObjectsAndKeys:@"automount", [NSNumber numberWithInt:RMFColumnAutomount],
                        @"label", [NSNumber numberWithInt:RMFColumnLabel],
                       @"size", [NSNumber numberWithInt:RMFColumnSize],
                       nil];
    
    _tableDelegate = [[RMFPresetsTableViewDelegate alloc] init];
    //[tableView addTableColumn:[[NSTableColumn alloc] initWithIdentifier:@"automount"]];
    tableView.dataSource = [[NSApp delegate] presetsManager];
    tableView.delegate = self.tableDelegate;
  }
  
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)addPreset:(id)sender
{
  RMFAppDelegate *delegate = [NSApp delegate];
  [delegate.presetsManager addNewVolumePreset];
  [tableView reloadData];
}

- (void)deletePreset:(id)sender
{
  // find the selected preset
  RMFAppDelegate *delegate = [NSApp delegate];
  [delegate.presetsManager deleteVolumePreset:nil];
  [tableView reloadData];
  
}

@end

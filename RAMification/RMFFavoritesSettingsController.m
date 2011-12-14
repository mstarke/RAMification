//
//  RMFPresetSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavoritesSettingsController.h"
#import "RMFRamdisk.h"
#import "RMFAppDelegate.h"

@implementation RMFFavoritesSettingsController

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
  NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:[RMFFavoritesSettingsController identifier]];
  [item setImage:[NSImage imageNamed:NSImageNameFolderSmart]];
  [item setLabel:[RMFFavoritesSettingsController label]];
  [item setAction:@selector(showSettings:)];
  return [item autorelease];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:@"FavoritesPane" bundle:[NSBundle mainBundle]];
  if (self)
  {
    columIdentifier = [NSDictionary dictionaryWithObjectsAndKeys:@"automount", [NSNumber numberWithInt:RMFColumnAutomount],
                        @"label", [NSNumber numberWithInt:RMFColumnLabel],
                       @"size", [NSNumber numberWithInt:RMFColumnSize],
                       nil];
    
    _tableDelegate = [[RMFPresetsTableViewDelegate alloc] init];
    //[tableView addTableColumn:[[NSTableColumn alloc] initWithIdentifier:@"automount"]];
    tableView.dataSource = [[NSApp delegate] favoritesManager];
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
  [delegate.favoritesManager addNewFavourite];
  [tableView reloadData];
}

- (void)deletePreset:(id)sender
{
  // find the selected preset
  RMFAppDelegate *delegate = [NSApp delegate];
  [delegate.favoritesManager deleteFavourite:nil];
  [tableView reloadData];
  
}

@end

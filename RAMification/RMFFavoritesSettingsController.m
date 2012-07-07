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
#import "RMFFavoriteManager.h"

@interface RMFFavoritesSettingsController ()
- (void) didLoadView;
@end

@implementation RMFFavoritesSettingsController

@synthesize tableDelegate = _tableDelegate;

+ (NSString *) identifier {
  return @"PresetSettings";
}

+ (NSString *) label {
  return NSLocalizedString(@"FAVOURITE_SETTINGS_LABEL", @"Label for the Preset Settings");
}

+ (NSToolbarItem *) toolbarItem {
  NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:[RMFFavoritesSettingsController identifier]];
  [item setImage:[NSImage imageNamed:NSImageNameFolderSmart]];
  [item setLabel:[RMFFavoritesSettingsController label]];
  [item setAction:@selector(showSettings:)];
  return [item autorelease];
}

#pragma mark init/dealloc

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:@"FavoritesPane" bundle:[NSBundle mainBundle]];
  if (self) {    
    // nothing to do;
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

#pragma mark view loading

// override to wait if a view was loaded
- (void)loadView {
  [super loadView];
  [self didLoadView];
}

- (void)didLoadView {
  _tableDelegate = [[RMFPresetsTableViewDelegate alloc] init];
  NSTableColumn *automountColumn = [[NSTableColumn alloc] initWithIdentifier:RMFKeyForAutomount];
  NSTableColumn *labelColumn = [[NSTableColumn alloc] initWithIdentifier:RMFKeyForLabel];
  NSTableColumn *sizeColumn = [[NSTableColumn alloc] initWithIdentifier:RMFKeyForSize];
  
  [[automountColumn headerCell] setStringValue:NSLocalizedString(@"COLUMN_HEADER_AUTOMOUNT", @"Column Header for the automount column")];
  [[labelColumn headerCell] setStringValue:NSLocalizedString(@"COLUMN_HEADER_LABEL", @"Column header for the label column")];
  [[sizeColumn headerCell] setStringValue:NSLocalizedString(@"COLUMN_HEADER_SIZE", @"Column header for the size column")];
  
  [tableView addTableColumn:automountColumn];
  [tableView addTableColumn:labelColumn];
  [tableView addTableColumn:sizeColumn];
  tableView.dataSource = [[NSApp delegate] favoritesManager];
  tableView.delegate = self.tableDelegate;
}

# pragma mark actions

- (void)addPreset:(id)sender {
  RMFAppDelegate *delegate = [NSApp delegate];
  [delegate.favoritesManager addNewFavourite];
  [tableView reloadData];
}

- (void)deletePreset:(id)sender {
  // find the selected preset
  RMFAppDelegate *delegate = [NSApp delegate];
  [delegate.favoritesManager deleteFavourite:[delegate.favoritesManager.favourites objectAtIndex:[tableView selectedRow]]];
  [tableView reloadData];
  
}

@end

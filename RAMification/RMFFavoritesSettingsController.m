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
#import "RMFFavouritesManager.h"

@interface RMFFavoritesSettingsController ()

@property (retain) RMFFavouritesTableViewDelegate *tableDelegate;

- (void) didLoadView;

@end

@implementation RMFFavoritesSettingsController

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
    NSLog(@"Created %@", [self class]);
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
  _tableDelegate = [[RMFFavouritesTableViewDelegate alloc] init];
  NSTableColumn *automountColumn = [[NSTableColumn alloc] initWithIdentifier:RMFRamdiskKeyForAutomount];
  NSTableColumn *labelColumn = [[NSTableColumn alloc] initWithIdentifier:RMFRamdiskKeyForLabel];
  NSTableColumn *sizeColumn = [[NSTableColumn alloc] initWithIdentifier:RMFRamdiskKeyForSize];
  NSTableColumn *backupModeColum = [[NSTableColumn alloc] initWithIdentifier:RMFRamdiskKeyForBackupMode];
  
  [[automountColumn headerCell] setStringValue:NSLocalizedString(@"COLUMN_HEADER_AUTOMOUNT", @"Column Header for the automount column")];
  [[labelColumn headerCell] setStringValue:NSLocalizedString(@"COLUMN_HEADER_LABEL", @"Column header for the label column")];
  [[sizeColumn headerCell] setStringValue:NSLocalizedString(@"COLUMN_HEADER_SIZE", @"Column header for the size column")];
  [[backupModeColum headerCell] setStringValue:NSLocalizedString(@"COLUMN_HEADER_BACKUP_MODE", @"The mode that backups are created")];
  
  [tableView addTableColumn:automountColumn];
  [tableView addTableColumn:labelColumn];
  [tableView addTableColumn:sizeColumn];
  [tableView addTableColumn:backupModeColum];
  
  [automountColumn release];
  [labelColumn release];
  [sizeColumn release];
  [backupModeColum release];
  
  tableView.dataSource = [RMFFavouritesManager sharedManager];
  tableView.delegate = self.tableDelegate;
}

# pragma mark actions

- (void)addPreset:(id)sender {
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  [favouriteManager addNewFavourite];
  [tableView reloadData];
}

- (void)deletePreset:(id)sender {
  // find the selected preset
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *selectedFavourite = [favouriteManager.favourites objectAtIndex:[tableView selectedRow]];
  [favouriteManager deleteFavourite:selectedFavourite];
  [tableView reloadData];
  
}

@end

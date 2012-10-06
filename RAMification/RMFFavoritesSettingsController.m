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
#import "RMFMountWatcher.h"

@interface RMFFavoritesSettingsController () {
  NSArrayController *_favouritesController;
}

@property (retain) RMFFavouritesTableViewDelegate *tableDelegate;

- (void)didLoadView;
- (void)didRenameFavourite:(NSNotification *)notification;
- (NSMenu *)allocBackupModePopupMenu;

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
  NSImage *toolbarImage = [[NSBundle mainBundle] imageForResource:@"favourite"];
  [item setImage:toolbarImage];
  [item setLabel:[RMFFavoritesSettingsController label]];
  [item setAction:@selector(showSettings:)];
  return [item autorelease];
}

#pragma mark init/dealloc
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:@"FavoritesPane" bundle:[NSBundle mainBundle]];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRenameFavourite:) name:RMFDidRenameRamdiskNotification object:nil];
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
  _favouritesController = [[NSArrayController alloc] init];
  NSArray *favourites = [[RMFFavouritesManager sharedManager] favourites];
  [_favouritesController setContent:favourites];
  [_favouriteColumn bind:NSValueBinding toObject:_favouritesController withKeyPath:NSContentArrayBinding options:nil];
  
  _tableDelegate = [[RMFFavouritesTableViewDelegate alloc] init];
  _favouritesTableView.delegate = self.tableDelegate;
  NSBundle *bundle = [NSBundle mainBundle];
  [self.volumeIconImageView setImage:[bundle imageForResource:@"Removable"]];
}

- (NSMenu *)allocBackupModePopupMenu {
  NSMenu *backupMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  for(NSUInteger eMode = 0; eMode < RMFBackupModeCount; eMode++) {
    switch (eMode) {
      case RMFNoBackup:
        [backupMenu addItemWithTitle:NSLocalizedString(@"RAMDISK_BACKUP_MODE_NO_BACKUP", @"Backup mode No Backup") action:NULL keyEquivalent:@""];
        break;
      case RMFBackupOnEject:
        [backupMenu addItemWithTitle:NSLocalizedString(@"RAMDISK_BACKUP_MODE_EJECT_ONLY", @"Backup mode Backup on Eject") action:NULL keyEquivalent:@""];
        break;
      case RMFBackupPeriodically:
        [backupMenu addItemWithTitle:NSLocalizedString(@"RAMDISK_BACKUP_MODE_PERIODICALLY", @"Backup mode Continously Backup") action:NULL keyEquivalent:@""];
        break;
    }
  }
  return  backupMenu;
}


# pragma mark actions
- (void)addPreset:(id)sender {
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  [favouriteManager addNewFavourite];
  //[_favouritesTableView reloadData];
}

- (void)deletePreset:(id)sender {
  // find the selected preset
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  NSInteger selectedRow = [_favouritesTableView selectedRow];
  if(-1 == selectedRow) {
    return;
  }
  RMFRamdisk *selectedFavourite = [favouriteManager.favourites objectAtIndex:selectedRow];
  [favouriteManager deleteFavourite:selectedFavourite];
  //[_favouritesTableView reloadData];
}

#pragma mark Notifications
- (void)didRenameFavourite:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  RMFRamdisk *ramdisk = [userInfo objectForKey:kRMFRamdiskKey];
  NSArray *favourites = [[RMFFavouritesManager sharedManager] favourites];
  NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndex:[favourites indexOfObject:ramdisk]];
//  NSIndexSet *columnIndexSet = [NSIndexSet indexSetWithIndex:[tableView columnWithIdentifier:kRMFRamdiskKeyForLabel]];
//  [tableView reloadDataForRowIndexes:rowIndexSet columnIndexes:columnIndexSet];
}

@end

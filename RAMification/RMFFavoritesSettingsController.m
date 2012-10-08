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
#import "RMFSizeFormatter.h"

@interface RMFFavoritesSettingsController () {
  NSArrayController *_favouritesController;
}

@property (retain) RMFFavouritesTableViewDelegate *tableDelegate;

- (void)didLoadView;
- (void)didRenameFavourite:(NSNotification *)notification;
- (NSMenu *)backupModePopupMenu;

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
  
  // Array controller for the table view selection
  _favouritesController = [[NSArrayController alloc] init];
  [_favouritesController bind:NSContentArrayBinding toObject:[RMFFavouritesManager sharedManager] withKeyPath:kRMFFavouritesManagerFavouritesKey options:nil];
  [_favouriteColumn bind:NSValueBinding toObject:_favouritesController withKeyPath:NSContentArrayBinding options:nil];
 
  _tableDelegate = [[RMFFavouritesTableViewDelegate alloc] init];
  _favouritesTableView.delegate = self.tableDelegate;
  
  [_detailBackupPopUp setMenu:[self backupModePopupMenu]];
  [_detailSizeTextField setFormatter:[RMFSizeFormatter formatter]];
 
  // Setup bindings for the detail view
  NSString *labelKeyPath = [NSString stringWithFormat:@"selection.%@", kRMFRamdiskKeyForLabel];
  NSString *automountKeyPath = [NSString stringWithFormat:@"selection.%@", kRMFRamdiskKeyForAutomount];
  NSString *sizeKeyPath = [NSString stringWithFormat:@"selection.%@", kRMFRamdiskKeyForSize];
  NSString *backupModeKeyPath = [NSString stringWithFormat:@"selection.%@", kRMFRamdiskKeyForBackupMode];
  NSString *volumeIconKeyPath = [NSString stringWithFormat:@"selection.%@", kRMFRamdiskKeyForVolumeIcon];
  [_detailLabelTextField bind:NSValueBinding toObject:_favouritesController withKeyPath:labelKeyPath options:nil];
  [_detailIsAutoMount bind:NSValueBinding toObject:_favouritesController withKeyPath:automountKeyPath options:nil];
  [_detailSizeTextField bind:NSValueBinding toObject:_favouritesController withKeyPath:sizeKeyPath options:nil];
  [_detailBackupPopUp bind:NSSelectedIndexBinding toObject:_favouritesController withKeyPath:backupModeKeyPath options:nil];
  [_volumeIconImageView bind:NSValueBinding toObject:_favouritesController withKeyPath:volumeIconKeyPath options:nil];

  NSBundle *bundle = [NSBundle mainBundle];
  [self.volumeIconImageView setImage:[bundle imageForResource:@"Removable"]];
}

- (NSMenu *)backupModePopupMenu {
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
  return [backupMenu autorelease];
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
  NSIndexSet *columIndexSet = [NSIndexSet indexSetWithIndex:0];
  [_favouritesTableView reloadDataForRowIndexes:rowIndexSet columnIndexes:columIndexSet];
}

@end

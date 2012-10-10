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
#import "RMFArrayController.h"
#import "RMFFavouritesArrayControllerDelegate.h"

@interface RMFFavoritesSettingsController () {
  RMFArrayController *_favouritesController;
  RMFFavouritesArrayControllerDelegate *_favouritesControllerDelegate;
}

@property (retain) RMFFavouritesTableViewDelegate *tableDelegate;

- (void)didLoadView;
- (void)didRenameFavourite:(NSNotification *)notification;
- (NSMenu *)backupModeMenu;
- (NSMenu *)labelMenu;
- (NSImage *)labelImageWithColor:(NSColor *)color;

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
  [_favouritesController release];
  [_favouritesControllerDelegate release];
  self.tableDelegate = nil;
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
  _favouritesController = [[RMFArrayController alloc] init];
  _favouritesControllerDelegate = [[RMFFavouritesArrayControllerDelegate alloc] init];
  _favouritesController.delegate = _favouritesControllerDelegate;
  
  [_favouritesController bind:NSContentArrayBinding toObject:[RMFFavouritesManager sharedManager] withKeyPath:kRMFFavouritesManagerFavouritesKey options:nil];
  [_favouriteColumn bind:NSValueBinding toObject:_favouritesController withKeyPath:NSContentArrayBinding options:nil];
 
  _tableDelegate = [[RMFFavouritesTableViewDelegate alloc] init];
  _favouritesTableView.delegate = self.tableDelegate;
  
  [_backupPopUpButton setMenu:[self backupModeMenu]];
  [_labelPopupButton setMenu:[self labelMenu]];
  
  [_sizeTextField setFormatter:[RMFSizeFormatter formatter]];
 
  // Setup bindings for the detail view
  NSString *selection = @"selection.%@";
  NSString *labelKeyPath = [NSString stringWithFormat:selection, kRMFRamdiskKeyForLabel];
  NSString *automountKeyPath = [NSString stringWithFormat:selection, kRMFRamdiskKeyForAutomount];
  NSString *sizeKeyPath = [NSString stringWithFormat:selection, kRMFRamdiskKeyForSize];
  NSString *backupModeKeyPath = [NSString stringWithFormat:selection, kRMFRamdiskKeyForBackupMode];
  NSString *volumeIconKeyPath = [NSString stringWithFormat:selection, kRMFRamdiskKeyForVolumeIcon];
  NSString *finderLabelIndexKeyPath = [NSString stringWithFormat:selection, kRMFRamdiskKeyForFinderLabelIndex];
  [_labelTextField bind:NSValueBinding toObject:_favouritesController withKeyPath:labelKeyPath options:nil];
  [_detailIsAutoMount bind:NSValueBinding toObject:_favouritesController withKeyPath:automountKeyPath options:nil];
  [_sizeTextField bind:NSValueBinding toObject:_favouritesController withKeyPath:sizeKeyPath options:nil];
  [_backupPopUpButton bind:NSSelectedIndexBinding toObject:_favouritesController withKeyPath:backupModeKeyPath options:nil];
  [_volumeIconImageView bind:NSValueBinding toObject:_favouritesController withKeyPath:volumeIconKeyPath options:nil];
  [_labelPopupButton bind:NSSelectedIndexBinding toObject:_favouritesController withKeyPath:finderLabelIndexKeyPath options:nil];
  
  [_removeRamdiskButton bind:NSEnabledBinding toObject:_favouritesController withKeyPath:@"canRemove" options:nil];

  NSBundle *bundle = [NSBundle mainBundle];
  [self.volumeIconImageView setImage:[bundle imageForResource:@"Removable"]];
}

- (NSMenu *)backupModeMenu {
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

- (NSMenu *)labelMenu {
  NSMenu *labelMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSArray *labelColors = [workspace fileLabelColors];
  for(NSString *label in [workspace fileLabels]) {
    NSUInteger index = [[workspace fileLabels] indexOfObject:label];
    NSColor *labelColor = [labelColors objectAtIndex:index];
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:label action:NULL keyEquivalent:@""];
    [item setImage:[self labelImageWithColor:labelColor]];
    [labelMenu addItem:item];
    [item release];
    
  }
  return [labelMenu autorelease];
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

- (NSImage *)labelImageWithColor:(NSColor *)color {
  NSColor *borderColor = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1];
  NSRect offscreenRect = NSMakeRect(0.0, 0.0, 12, 12.0);
  NSBitmapImageRep* offscreenRep = nil;
  
  offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                         pixelsWide:offscreenRect.size.width
                                                         pixelsHigh:offscreenRect.size.height
                                                      bitsPerSample:8
                                                    samplesPerPixel:4
                                                           hasAlpha:YES
                                                           isPlanar:NO
                                                     colorSpaceName:NSCalibratedRGBColorSpace
                                                       bitmapFormat:0
                                                        bytesPerRow:(4 * offscreenRect.size.width)
                                                       bitsPerPixel:32];
  
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep]];
  [color setFill];
  NSRectFill(offscreenRect);
  [borderColor setFill];
  NSFrameRect(offscreenRect);
  [NSGraphicsContext restoreGraphicsState];
  NSImage *image = [[NSImage alloc] initWithSize:offscreenRect.size];
  [image addRepresentation:offscreenRep];
  [offscreenRep release];
  return [image autorelease];
}


@end

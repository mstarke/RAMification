//
//  RMFTableViewDelegate.m
//  RAMification
//
//  Created by Michael Starke on 01.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouritesTableViewDelegate.h"

#import "RMFFavouritesManager.h"
#import "RMFSizeFormatter.h"
#import "RMFRamdisk.h"
#import "RMFFavouriteCellView.h"

@implementation RMFFavouritesTableViewDelegate

- (id)init {
  self = [super init];
  return self;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if(tableColumn == nil) {
    return false;
  }
  NSArray *columns = [NSArray arrayWithObjects:kRMFRamdiskKeyForLabel, kRMFRamdiskKeyForSize, nil];
  if([columns containsObject:[tableColumn identifier]]) {
    RMFFavouritesManager *favouriteManager = [tableView dataSource];
    RMFRamdisk *ramdisk = [favouriteManager.favourites objectAtIndex:row];
    // We just prevent edition of the label and the size of mounted disks
    // Since these values would need us to remount the disk
    return (ramdisk.isMounted == NO);
  }
  return YES;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFFavouriteCellView *cellView = [tableView makeViewWithIdentifier:@"FavouriteCell" owner:self];
  RMFRamdisk *ramdisk = [[[RMFFavouritesManager sharedManager] favourites] objectAtIndex:row];
  [cellView.lableTextField setStringValue:ramdisk.label];
  [cellView.infoTextField setStringValue:[NSString stringWithFormat:@"%ld KB", ramdisk.size]];
  return cellView;
}

// return the cell for a column
- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if(tableColumn == nil) {
    return nil;
  }
  if([[tableColumn identifier] isEqualToString:kRMFRamdiskKeyForAutomount]) {
    NSButtonCell *buttonCell = [[NSButtonCell alloc] init];
    [buttonCell setButtonType:NSSwitchButton];
    [buttonCell setTitle:@""];
    [buttonCell setAlignment:NSCenterTextAlignment];
    return  [buttonCell autorelease]; // Checkbox cells
  }
  if([[tableColumn identifier] isEqualToString:kRMFRamdiskKeyForBackupMode]) {
    NSPopUpButtonCell *popUpCell = [[NSPopUpButtonCell alloc] init];
    [popUpCell setControlSize:NSMiniControlSize];
    NSMenu *buttonMenu = [self allocBackupModePopupMenu];
    [popUpCell setMenu:buttonMenu];
    [buttonMenu release];
    return  [popUpCell autorelease]; // PopUp cells
  }
  NSTextFieldCell *textCell = [[NSTextFieldCell alloc] init];
  if([[tableColumn identifier] isEqualToString:kRMFRamdiskKeyForSize]) {
    [textCell setFormatter:[RMFSizeFormatter formatter]];
  }
  [textCell setEditable:YES];
  
  return [textCell autorelease]; // TextField cells
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

@end

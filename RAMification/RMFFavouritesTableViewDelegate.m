//
//  RMFTableViewDelegate.m
//  RAMification
//
//  Created by Michael Starke on 01.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouritesTableViewDelegate.h"

#import "RMFRamdisk.h"

@implementation RMFFavouritesTableViewDelegate

- (id)init {
  self = [super init];
  if (self) {
    // Just create the Menu vor the popup once so we do not have to built it ever time;
  }
  return self;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if(tableColumn == nil) {
    return nil;
  }
  if([[tableColumn identifier] isEqualToString:RMFRamdiskKeyForAutomount]) {
    NSButtonCell *buttonCell = [[NSButtonCell alloc] init];
    [buttonCell setButtonType:NSSwitchButton];
    [buttonCell setTitle:@""];
    [buttonCell setAlignment:NSCenterTextAlignment];
    return  [buttonCell autorelease]; // Checkbox cells
  }
  if([[tableColumn identifier] isEqualToString:RMFRamdiskKeyForBackupMode]) {
    NSPopUpButtonCell *popUpCell = [[NSPopUpButtonCell alloc] init];
    [popUpCell setControlSize:NSMiniControlSize];
    NSMenu *buttonMenu = [self allocBackupModePopupMenu];
    [popUpCell setMenu:buttonMenu];
    [buttonMenu release];
    return  [popUpCell autorelease]; // PopUp cells
  }
  NSTextFieldCell *textCell = [[NSTextFieldCell alloc] init];
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

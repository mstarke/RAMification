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

@synthesize tableDataSource = _tableDataSource;
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
      _tableDataSource = [[RMFPresetsTableDataSource alloc] init];
      _tableDelegate = [[RMFPresetsTableViewDelegate alloc] init];
      tableView.dataSource = self.tableDataSource;
      tableView.delegate = self.tableDelegate;
    }
    
    return self;
}

- (void)dealloc {
  self.tableDataSource = nil;
  [super dealloc];
}

@end

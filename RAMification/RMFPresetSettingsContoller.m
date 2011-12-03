//
//  RMFPresetSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFPresetSettingsContoller.h"
#import "RMFAppDelegate.h"

@implementation RMFPresetSettingsContoller

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
  NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:[RMFPresetSettingsContoller identifier]];
  [item setImage:[NSImage imageNamed:NSImageNameFolderSmart]];
  [item setAction:@selector(showSettingsPane:)];
  id delegate = [NSApp delegate];
  [item setTarget:((RMFAppDelegate*)delegate).settingsController];
  [item setAction:@selector(showSettings:)];
  return [item autorelease];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

//
//  RMFPresetSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFPresetSettingsContoller.h"

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

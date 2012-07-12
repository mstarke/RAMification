//
//  RMFTableViewDelegate.m
//  RAMification
//
//  Created by Michael Starke on 01.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFPresetsTableViewDelegate.h"

#import "RMFRamdisk.h"

@implementation RMFPresetsTableViewDelegate

- (id)init {
  self = [super init];
  if (self) {
    // Nothing to do
  }
  return self;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if(tableColumn == nil) {
    return nil;
  }
  NSCell *cell;
  if([[tableColumn identifier] isEqualToString:RMFKeyForAutomount]) {
    cell = [[NSButtonCell alloc] init];
    NSButtonCell *buttonCell = (NSButtonCell *)cell;
    [buttonCell setButtonType:NSSwitchButton];
    [buttonCell setTitle:@""];
  }
  else {
    cell = [[NSTextFieldCell alloc] init];
  }
  return cell;
}

@end

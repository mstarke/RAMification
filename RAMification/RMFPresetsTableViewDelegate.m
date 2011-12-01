//
//  RMFTableViewDelegate.m
//  RAMification
//
//  Created by Michael Starke on 01.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFPresetsTableViewDelegate.h"

@implementation RMFPresetsTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return 10;
}

- (id)init {
  self = [super init];
  if (self)
  {
    
  }
  return self;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  id value;
  
  if(tableView.identifier == @"automount")
  {
    value = [NSNumber numberWithBool:YES];
  }
  else
  {
    value = @"Test";
  }
  
  return value;
}

@end

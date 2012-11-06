//
//  RMFTableViewDelegate.m
//  RAMification
//
//  Created by Michael Starke on 01.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouritesTableViewDelegate.h"

#import "RMFFavouritesManager.h"
#import "RMFRamdisk.h"
#import "RMFFavouriteCellView.h"

@implementation RMFFavouritesTableViewDelegate

- (id)init {
  self = [super init];
  return self;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFFavouriteCellView *cellView = [tableView makeViewWithIdentifier:@"FavouriteCell" owner:self];
  RMFRamdisk *ramdisk = [[[RMFFavouritesManager sharedManager] favourites] objectAtIndex:row];
  // Bind the Cell view to automatically update on changes
  [cellView.lableTextField bind:NSValueBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForLabel options:nil];
  [cellView.infoTextField bind:NSValueBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForSize options:nil];
  [cellView.imageView bind:NSEnabledBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForIsMounted options:nil];
  [cellView bind:kRMFFavouriteCellViewKeyForIsDefault toObject:ramdisk withKeyPath:kRMFRamdiskKeyForIsDefault options:nil];
   
  return cellView;
}

@end

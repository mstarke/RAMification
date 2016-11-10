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
#import "RMFLabelTextField.h"

@implementation RMFFavouritesTableViewDelegate

- (instancetype)init {
  self = [super init];
  return self;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFFavouriteCellView *cellView = [tableView makeViewWithIdentifier:@"FavouriteCell" owner:self];
  RMFRamdisk *ramdisk = [RMFFavouritesManager sharedManager].favourites[row];
  // Bind the Cell view to automatically update on changes
  [cellView.lableTextField bind:NSValueBinding toObject:ramdisk withKeyPath:NSStringFromSelector(@selector(label)) options:nil];
  [cellView.lableTextField bind:kRMFLabelTextFieldFinderLabelIndexKey toObject:ramdisk withKeyPath:NSStringFromSelector(@selector(finderLabelIndex)) options:nil];
  [cellView.infoTextField bind:NSValueBinding toObject:ramdisk withKeyPath:NSStringFromSelector(@selector(size)) options:nil];
  [cellView.imageView bind:NSEnabledBinding toObject:ramdisk withKeyPath:NSStringFromSelector(@selector(isMounted)) options:nil];
  [cellView bind:kRMFFavouriteCellViewKeyForIsDefault toObject:ramdisk withKeyPath:NSStringFromSelector(@selector(isDefault)) options:nil];
   
  return cellView;
}

@end

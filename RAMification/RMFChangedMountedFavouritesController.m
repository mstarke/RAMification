//
//  RMFChangedMountedFavouritesController.m
//  RAMification
//
//  Created by michael starke on 06.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFChangedMountedFavouritesController.h"

static NSString *const kRMFChangedMountedFavouritesControllerKeyForChagendeFavourites = @"changedFavourites";
static NSString *const kRMFChangedMountedFavouritesControllerFavouriteColumnIdentifier = @"ChangedFavouritess";

@interface RMFChangedMountedFavouritesController ()

@property (retain) NSArray *dummyObjects;
@property (assign) IBOutlet NSTableView *favouritesTableView;
@property (assign) IBOutlet NSTableColumn *favouritesColumn;
@property (retain) NSArrayController *favouritesController;

@end

@implementation RMFChangedMountedFavouritesController

- (id)init {
  return [self initWithWindowNibName:@"ChangedMountedFavourites"];
}

- (id)initWithWindow:(NSWindow *)window {
  self = [super initWithWindow:window];
  if (self) {
    self.dummyObjects = @[ @"dummy", @"dummy", @"dummy", @"dummy", @"dummy" ];
  }
  return self;
}

- (void)windowDidLoad {
  [super windowDidLoad];
  // set the identifier
  [_favouritesColumn setIdentifier:kRMFChangedMountedFavouritesControllerFavouriteColumnIdentifier];
  [_favouritesTableView setDelegate:self];
  
  // Value binding
  _favouritesController = [[NSArrayController alloc] init];
  [_favouritesController bind:NSContentArrayBinding toObject:self withKeyPath:kRMFChangedMountedFavouritesControllerKeyForChagendeFavourites options:0];
  [_favouritesColumn bind:NSValueBinding toObject:_favouritesController withKeyPath:NSContentArrayBinding options:nil];

}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTableCellView *cellView = [tableView makeViewWithIdentifier:kRMFChangedMountedFavouritesControllerFavouriteColumnIdentifier owner:self];
//  RMFRamdisk *ramdisk = [[[RMFFavouritesManager sharedManager] favourites] objectAtIndex:row];
//  // Bind the Cell view to automatically update on changes
//  [cellView.lableTextField bind:NSValueBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForLabel options:nil];
//  [cellView.infoTextField bind:NSValueBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForSize options:nil];
//  [cellView.imageView bind:NSEnabledBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForIsMounted options:nil];
//  [cellView bind:kRMFFavouriteCellViewKeyForIsDefault toObject:ramdisk withKeyPath:kRMFRamdiskKeyForIsDefault options:nil];
  
  return cellView;
}

@end

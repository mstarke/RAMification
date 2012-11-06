//
//  RMFChangedMountedFavouritesController.m
//  RAMification
//
//  Created by michael starke on 06.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFChangedMountedFavouritesController.h"

#import "RMFRamdisk.h"
#import "RMFFavouritesManager.h"
#import "RMFChangedMountedFavouriteCellView.h"

static NSString *const kRMFChangedMountedFavouritesControllerKeyForChagendeFavourites = @"changedFavourites";

@interface RMFChangedMountedFavouritesController ()

@property (assign) IBOutlet NSTableView *favouritesTableView;
@property (assign) IBOutlet NSTableColumn *favouritesColumn;
@property (assign) IBOutlet NSImageView *warningImageView;
@property (retain) NSArrayController *favouritesController;

- (IBAction)cancel:(id)sender;
- (IBAction)update:(id)sender;

@end

@implementation RMFChangedMountedFavouritesController

- (id)init {
  return [self initWithWindowNibName:@"ChangedMountedFavourites"];
}

- (void)windowDidLoad {
  [super windowDidLoad];
  // GUI fixup
  [self.window setTitle:NSLocalizedString(@"WINDOW_FAVOURITE_NAME_CHANGED_TITLE", @"Title for the Window displaying changed mounted favourites after launch")];
  [_warningImageView setImage:[NSImage imageNamed:NSImageNameCaution]];
  
  [_favouritesTableView setDelegate:self];
  // Table view population
  _favouritesController = [[NSArrayController alloc] init];
  [_favouritesController bind:NSContentArrayBinding toObject:self withKeyPath:kRMFChangedMountedFavouritesControllerKeyForChagendeFavourites options:0];
  [_favouritesColumn bind:NSValueBinding toObject:_favouritesController withKeyPath:NSContentArrayBinding options:nil];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFChangedMountedFavouriteCellView *cellView = [tableView makeViewWithIdentifier:@"ChangedFavouriteView" owner:self];
  RMFRamdisk *ramdisk = [[[RMFFavouritesManager sharedManager] favourites] objectAtIndex:row];
  // Bind the Cell view to automatically update on changes
  [cellView.textField bind:NSValueBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForLabel options:nil];
  [cellView.imageView bind:NSEnabledBinding toObject:ramdisk withKeyPath:kRMFRamdiskKeyForIsMounted options:nil];
  
  return cellView;
}

- (IBAction)cancel:(id)sender {
  [self.window close];
}

- (IBAction)update:(id)sender {
  [self.window close];
}
@end

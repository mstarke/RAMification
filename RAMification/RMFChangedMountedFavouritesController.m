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

static NSString *const kRMFChangedMountedFavouritesControllerKeyForChagendeFavourites = @"changedFavouritesWrapper";
static NSString *const kRMFChangedFavouriteRamdiskKey = @"kRMFChangedFavouriteRamdiskKey";
static NSString *const kRMFChangedFavouriteUpdateActionKey = @"kRMFChangedFavouriteUpdateAction";

static NSMutableDictionary *RMFCreateFavouritesEntry(RMFRamdisk *ramdiks) {
  NSDictionary *dict = @{ kRMFChangedFavouriteRamdiskKey: ramdiks, kRMFChangedFavouriteUpdateActionKey: @(RMFChangedFavouriteIgnoreAction) };
  NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
  [mutableDict addEntriesFromDictionary:dict];
  return mutableDict;
}

@interface RMFChangedMountedFavouritesController ()

@property (weak) IBOutlet NSTableView *favouritesTableView;
@property (weak) IBOutlet NSTableColumn *favouritesColumn;
@property (weak) IBOutlet NSImageView *warningImageView;

@property (strong) NSMutableArray *changedFavouritesWrapper;
@property (strong) NSArrayController *favouritesController;

@end

@implementation RMFChangedMountedFavouritesController

- (instancetype)init {
  return [self initWithWindowNibName:@"ChangedMountedFavourites"];
}

- (void)setChangedFavourites:(NSArray *)favourites {
  if(nil == _changedFavouritesWrapper ) {
    _changedFavouritesWrapper = [[NSMutableArray alloc] init];
  }
  else {
    [_changedFavouritesWrapper removeAllObjects];
  }
  for(RMFRamdisk *ramdisk in favourites) {
    [_changedFavouritesWrapper insertObject:RMFCreateFavouritesEntry(ramdisk) atIndex:_changedFavouritesWrapper.count];
  }
}

- (void)windowDidLoad {
  [super windowDidLoad];
  // GUI setup
  [self.window setTitle:NSLocalizedString(@"WINDOW_FAVOURITE_NAME_CHANGED_TITLE", @"Title for the Window displaying changed mounted favourites after launch")];
  _warningImageView.image = [NSImage imageNamed:NSImageNameCaution];
  
  
  _favouritesTableView.delegate = self;
  // Table view population
  _favouritesController = [[NSArrayController alloc] init];
  [_favouritesController bind:NSContentArrayBinding toObject:self withKeyPath:kRMFChangedMountedFavouritesControllerKeyForChagendeFavourites options:0];
  [_favouritesColumn bind:NSValueBinding toObject:_favouritesController withKeyPath:NSContentArrayBinding options:nil];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFChangedMountedFavouriteCellView *cellView = [tableView makeViewWithIdentifier:@"ChangedFavouriteView" owner:self];
  NSMutableDictionary *rowDict = (self.changedFavouritesWrapper)[row];
  RMFRamdisk *ramdisk = rowDict[kRMFChangedFavouriteRamdiskKey];
  // Bind the Cell view to automatically update on changes
  
  [cellView.textField bind:NSValueBinding toObject:ramdisk withKeyPath:NSStringFromSelector(@selector(label)) options:nil];
  [cellView.imageView bind:NSEnabledBinding toObject:ramdisk withKeyPath:NSStringFromSelector(@selector(isMounted)) options:nil];
  [cellView.actionSelectionControl bind:NSSelectedIndexBinding toObject:rowDict withKeyPath:kRMFChangedFavouriteUpdateActionKey options:0];
  return cellView;
}

- (IBAction)cancel:(id)sender {
  [self.window close];
}

- (IBAction)update:(id)sender {
  
  for(NSDictionary *wrapperDict in self.changedFavouritesWrapper) {
    RMFChangedFavouriteUpdateAction action = (RMFChangedFavouriteUpdateAction)[wrapperDict[kRMFChangedFavouriteUpdateActionKey] integerValue];
    RMFRamdisk *ramdisk = wrapperDict[kRMFChangedFavouriteRamdiskKey];
    
    switch(action) {
      case RMFChangedFavouriteRevertVolume: {
        [ramdisk.volumeURL setResourceValue:ramdisk.label forKey:NSURLNameKey error:nil];
        break;
      }
      case RMFChangedFavouriteUpdateFavourite:
        ramdisk.label = (ramdisk.volumeURL).lastPathComponent;
        break;
      case RMFChangedFavouriteIgnoreAction:
      default:
        break;
    }
  }
  
  [self.window close];
}
@end

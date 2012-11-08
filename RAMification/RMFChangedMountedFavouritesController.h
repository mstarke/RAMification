//
//  RMFChangedMountedFavouritesController.h
//  RAMification
//
//  Created by michael starke on 06.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 The order must be the same as in the nib file
 */
typedef enum RMFChangedFavouriteUpdateActionType {
  RMFChangedFavouriteUpdateFavourite,
  RMFChangedFavouriteRevertVolume,
  RMFChangedFavouriteIgnoreAction,
  RMFChangedFavouriteActionCount // Do not use, for coutning only
} RMFChangedFavouriteUpdateAction;

@interface RMFChangedMountedFavouritesController : NSWindowController <NSTableViewDelegate>

- (void)setChangedFavourites:(NSArray *)favourites;

@end

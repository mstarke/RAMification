//
//  RMFChangedMountedFavouritesController.h
//  RAMification
//
//  Created by michael starke on 06.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RMFChangedMountedFavouritesController : NSWindowController <NSTableViewDelegate>

@property (retain) NSArray *changedFavourites;

@end

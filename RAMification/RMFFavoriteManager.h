//
//  RMFPresetManager.h
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RMFRamdisk;

// Manager to handle all favourites. It's used to create, remove, mount and unmount ramdisks
@interface RMFFavoriteManager : NSObject <NSTableViewDataSource>

// List of all known favourites
@property (readonly, retain) NSMutableArray *favourites;

// Finds all mounted favourites
// @return array of mounted favourites
- (NSArray *)mountedFavourites;

// Add a new Favourite
// @return created ramdisk, nil if none was created
- (RMFRamdisk *)addNewFavourite;

// Find a favourite with the exact given name (no wildcards, no substring)
// @param name the name to search
// @return mathing favourite, nil if none was found
- (RMFRamdisk *)findFavouriteForName:(NSString *)name;

// Find a favourite with the given device path
// @param path the Device path to look for
// @return matching favourite, nil if nothing was found
- (RMFRamdisk *)findFavouriteForDevicePath:(NSString *)path;

// Delete the given favourite
// @param ramdisk favourite to delete
- (void) deleteFavourite:(RMFRamdisk *)ramdisk;

// update favourites
- (void) updateFavourites;


@end

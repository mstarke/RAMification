//
//  RMFPresetManager.h
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFRamdisk.h"

@interface RMFFavoriteManager : NSObject <NSTableViewDataSource>

@property (readonly, retain) NSMutableArray *favourites;

- (NSArray*) mountedFavourites;
- (BOOL) addFavourite:(RMFRamdisk*) ramdisk;
- (RMFRamdisk*) addNewFavourite;
- (RMFRamdisk*) createUniqueFavourite;
- (RMFRamdisk*) findFavouriteForName:(NSString*)name;
- (void) deleteFavourite:(RMFRamdisk *)ramdisk;
- (void) synchronizeDefaults;
- (void) updateFavourites;


@end

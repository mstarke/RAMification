//
//  RMFPresetManager.h
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFRamdisk.h"

extern NSString *const RMFPresetsPreferencesKey;

@interface RMFFavoriteManager : NSObject <NSTableViewDataSource>

@property (readonly, retain) NSMutableArray *favourites;

- (NSArray*) mountedFavourites;
- (BOOL) addFavourite:(RMFRamdisk*) ramdisk;
- (RMFRamdisk*) addNewFavourite;
- (RMFRamdisk*) createUniqueFavourite;
- (void) deleteFavourite:(RMFRamdisk *)favourite;
- (void) synchronizeDefaults;
- (void) updateFavourites;


@end

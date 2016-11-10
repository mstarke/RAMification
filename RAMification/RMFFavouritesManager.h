//
//  RMFPresetManager.h
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

APPKIT_EXTERN NSString *const kRMFFavouritesManagerKeyForFavourites;
APPKIT_EXTERN NSString *const kRMFFavouritesManagerFavouritesKeyForDefaultRamdisk;

@class RMFRamdisk;

/*
 Manager to handle all favourites. It's used to create, remove, mount and unmount ramdisks
 It gives a interface to search for favourites based on different criteria
 */
@interface RMFFavouritesManager : NSObject

/*
 List of all known favourites
 */
@property (readonly, strong) NSMutableArray *favourites;


/*
 Returns the global favourites manager
 */
+ (RMFFavouritesManager *)sharedManager;

/*
 Finds all mounted favourites
 @return array of mounted favourites
 */
@property (nonatomic, readonly, copy) NSArray *mountedFavourites;

/*
 Add a new Favourite
 @return created ramdisk, nil if none was created
 */
- (RMFRamdisk *)addNewFavourite;

/*
 Find a favourite with the exact given name (no wildcards, no substring)
 @param name the name to search
 @return mathing favourite, nil if none was found
 */
- (RMFRamdisk *)findFavouriteByName:(NSString *)name;

/*
 Find a favourite with the given volume URL
 @param url the Device url to look for
 @return first matching favourite, nil if nothing was found
 */
- (RMFRamdisk *)findFavouriteWithVolumeURL:(NSURL *)url;

/*
 Looks for the Favourite with the given bsd device name
 @param device the bsd device to look for
 */
- (RMFRamdisk *)findFavouriteWithBsdDevice:(NSString *)device;

/*
 Find Ramdisk by using UUID
 @param uuid NSUUID to look for
 */
- (RMFRamdisk *)findFavouriteByUUID:(NSUUID *)uuid;

/*
 Delete the given favourite
 @param ramdisk favourite to delete
 */
- (void)deleteFavourite:(RMFRamdisk *)ramdisk;

/*
 initalize Favourites
 */
- (void)automountFavourites;

- (void)setDefaultRamdisk:(RMFRamdisk *)ramdisk;
- (RMFRamdisk *)defaultRamdisk;

@end

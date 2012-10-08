//
//  RMFPresetManager.m
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouritesManager.h"

#import "RMFAppDelegate.h"
#import "RMFRamdisk.h"
#import "RMFMountController.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"
#import "RMFFavouritesTableViewDelegate.h"

NSString *const kRMFFavouritesManagerFavouritesKey = @"favourites";

// private interface
@interface RMFFavouritesManager ()

@property (retain) NSMutableArray *favourites;

/*
 Adds the given ramdisk to the favourites
 @param ramdisk favourite to add
 @return true if the favourite was added, false otherwise
 */
- (BOOL) addFavourite:(RMFRamdisk*) ramdisk;
/*
 creates a default favourite with a unique name
 @return the unique favourite
 */
- (RMFRamdisk*) createUniqueFavourite;
/*
 Obseverse ramdisk for changes to values stored in user defaults
 and shedules synchornization on relevant changes
 */
- (void)observerRamdisk:(RMFRamdisk *)ramdisk;
/*
 Stores favourites to defaults
 */
- (void) synchronizeDefaults;

@end


static RMFFavouritesManager *sharedSingleton;

// actual implementation
@implementation RMFFavouritesManager

#pragma mark convenience functions

+ (void)initialize {
  static BOOL initialized = NO;
  if(!initialized) {
    initialized = YES;
    sharedSingleton = [[RMFFavouritesManager alloc] init];
  }
}

+ (RMFFavouritesManager *)sharedManager {
  return sharedSingleton;
}

#pragma mark object lifecycle

- (id)init {
  self = [super init];
  
  if (self) {
    NSLog(@"Trying to load presets!");
    self.favourites = [NSMutableArray array];
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kRMFSettingsKeyFavourites];
    if(data != nil) {
      NSArray *favourites = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if(favourites != nil) {
        self.favourites = [NSMutableArray arrayWithArray:favourites];
        for(RMFRamdisk *ramdisk in _favourites) {
          [self observerRamdisk:ramdisk];
        }
      }
    }
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  self.favourites = nil;
  [super dealloc];
}

#pragma mark NSTabelDataSource protocoll

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [_favourites count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFRamdisk *favourite = [_favourites objectAtIndex:row];
  // We need to wrap the identifier in a Number with bool to get the checkbox right
  if([tableColumn.identifier isEqualToString:kRMFRamdiskKeyForAutomount]) {
    return [NSNumber numberWithBool:favourite.isAutomount];
  }
  return [favourite valueForKey:[tableColumn identifier]];
}


#pragma mark preset handling

- (RMFRamdisk *)createUniqueFavourite {
  NSString *testpath = @"/Users/michael/Desktop/Test";
  NSString *unique = [NSString uniqueVolumeName:@"hallo" inFolder:testpath];
  NSLog(@"Unique Volume name: %@", unique);
  return [RMFRamdisk volumePreset];
}

-(RMFRamdisk *)addNewFavourite {
  RMFRamdisk* ramdisk = [self createUniqueFavourite];
  [self addFavourite:ramdisk];
  return ramdisk;
}

- (NSArray *)mountedFavourites {
  return [_favourites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (BOOL)addFavourite:(RMFRamdisk *)ramdisk {
  BOOL isDuplicate = [_favourites containsObject:ramdisk];
  if(!isDuplicate) {
    [self insertObject:ramdisk inFavouritesAtIndex:[_favourites count]];
    [self observerRamdisk:ramdisk];
    [self synchronizeDefaults];
  }
  return !isDuplicate;
}

- (void)deleteFavourite:(RMFRamdisk *)ramdisk {
  NSUInteger index = [_favourites indexOfObject:ramdisk];
  [self removeObjectFromFavouritesAtIndex:index];
  [self synchronizeDefaults];
}

- (RMFRamdisk *)findFavouriteByName:(NSString*)name {
  for(RMFRamdisk *ramdisk in _favourites) {
    if([ramdisk.label isEqualToString:name]) {
      return ramdisk;
    }
  }
  return nil;}

- (RMFRamdisk *)findFavouriteWithVolumePath:(NSString *)path {
  for(RMFRamdisk *ramdisk in _favourites) {
    if([ramdisk.volumePath isEqualToString:path]) {
      return ramdisk;
    }
  }
  return nil;
}

- (RMFRamdisk *)findFavouriteWithBsdDevice:(NSString *)device {
  for(RMFRamdisk *ramdisk in _favourites){
    if([ramdisk.bsdDevice isEqualToString:device]) {
      return ramdisk;
    }
  }
  return nil;
}

- (void)updateFavourites {
  // update favourites
}

- (void)initializeFavourites {
  for(RMFRamdisk *ramdisk in _favourites) {
    if(ramdisk.isAutomount) {
      RMFMountController *mountController = [RMFMountController sharedController];
      [mountController mount:ramdisk];
    }
  }
}

- (void)observerRamdisk:(RMFRamdisk *)ramdisk {
  if(ramdisk != nil) {
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForAutomount options:NSKeyValueObservingOptionNew context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForBackupMode options:NSKeyValueObservingOptionNew context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForLabel options:NSKeyValueObservingOptionNew context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForSize options:NSKeyValueObservingOptionNew context:nil];
  }
}
# pragma mark KVC

- (void) removeObjectFromFavouritesAtIndex:(NSUInteger)index {
  [_favourites removeObjectAtIndex:index];
}

- (void)insertObject:(RMFRamdisk *)ramdisk inFavouritesAtIndex:(NSUInteger)index {
  [_favourites insertObject:ramdisk atIndex:index];
}

- (id)objectInFavouritesAtIndex:(NSUInteger)index {
  return [_favourites objectAtIndex:index];
}

- (NSUInteger)countOfFavourites {
  return [_favourites count];
}

#pragma makr KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if([object isKindOfClass:[RMFRamdisk class]]) {
    [self synchronizeDefaults];
  }
}

- (void)synchronizeDefaults {
  NSData *data= [NSKeyedArchiver archivedDataWithRootObject:_favourites];
  
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:kRMFSettingsKeyFavourites];
  [[NSUserDefaults standardUserDefaults] synchronize];
}



@end
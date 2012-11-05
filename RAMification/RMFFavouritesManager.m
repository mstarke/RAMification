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
#import "RMFMountWatcher.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"
#import "RMFFavouritesTableViewDelegate.h"

NSString *const kRMFFavouritesManagerKeyForFavourites = @"favourites";
NSString *const kRMFFavouritesManagerFavouritesKeyForDefaultRamdisk = @"defaultRamdisk";


// private interface
@interface RMFFavouritesManager ()

@property (retain) NSMutableArray *favourites;
@property (nonatomic, assign) NSInteger defaultRamdiskIndex;
@property (retain) NSMutableDictionary *uuidToFavourites;

/*
 Adds the given ramdisk to the favourites
 @param ramdisk favourite to add
 @return true if the favourite was added, false otherwise
 */
- (BOOL)_addFavourite:(RMFRamdisk*) ramdisk;
/*
 creates a default favourite with a unique name
 @return the unique favourite
 */
- (RMFRamdisk *)_createUniqueFavourite;
/*
 Obseverse ramdisk for changes to values stored in user defaults
 and shedules synchornization on relevant changes
 */
- (void)_observerRamdisk:(RMFRamdisk *)ramdisk;

- (void)_createUUIDDictionary;
- (void)_synchronizeDefaults;
- (void)_validateDefaultRamdisk;

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
    self.defaultRamdiskIndex = NSNotFound;
    self.favourites = [NSMutableArray array];
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kRMFSettingsKeyFavourites];
    if(data != nil) {
      NSArray *favourites = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if(favourites != nil) {
        [_favourites addObjectsFromArray:favourites];
      }
    }
    // We use the favourites as defualts so we need at least one!
    if(0 == [_favourites count]) {
      RMFRamdisk *defaultRamdisk = [RMFRamdisk defaultRamdisk];
      [_favourites addObject:defaultRamdisk];
    }
    [self _createUUIDDictionary];
    [self _validateDefaultRamdisk];
    NSLog(@"%@", _favourites);
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  for(RMFRamdisk *ramdisk in _favourites) {
    [ramdisk removeObserver:self forKeyPath:kRMFRamdiskKeyForAutomount];
    [ramdisk removeObserver:self forKeyPath:kRMFRamdiskKeyForBackupMode];
    [ramdisk removeObserver:self forKeyPath:kRMFRamdiskKeyForLabel];
    [ramdisk removeObserver:self forKeyPath:kRMFRamdiskKeyForSize];
    [ramdisk removeObserver:self forKeyPath:kRMFRamdiskKeyForFinderLabelIndex];
    [ramdisk removeObserver:self forKeyPath:kRMFRamdiskKeyForIsDefault];
  }
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

- (RMFRamdisk *)_createUniqueFavourite {
  NSString *testpath = @"/Users/michael/Desktop/Test";
  NSString *unique = [NSString uniqueVolumeName:@"hallo" inFolder:testpath];
  NSLog(@"Unique Volume name: %@", unique);
  return [RMFRamdisk defaultRamdisk];
}

-(RMFRamdisk *)addNewFavourite {
  RMFRamdisk* ramdisk = [self _createUniqueFavourite];
  [self _addFavourite:ramdisk];
  return ramdisk;
}

- (NSArray *)mountedFavourites {
  return [_favourites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (BOOL)_addFavourite:(RMFRamdisk *)ramdisk {
  BOOL isDuplicate = [_favourites containsObject:ramdisk];
  if(!isDuplicate) {
    [self insertObject:ramdisk inFavouritesAtIndex:[_favourites count]];
    [_uuidToFavourites setObject:ramdisk forKey:ramdisk.uuid];
    [self _observerRamdisk:ramdisk];
    [self _synchronizeDefaults];
  }
  return !isDuplicate;
}

- (void)deleteFavourite:(RMFRamdisk *)ramdisk {
  NSUInteger index = [_favourites indexOfObject:ramdisk];
  [self removeObjectFromFavouritesAtIndex:index];
  [_uuidToFavourites removeObjectForKey:ramdisk.uuid];
  [self _synchronizeDefaults];
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

- (RMFRamdisk *)findFavouriteByUUID:(NSString *)uuid {
  return [_uuidToFavourites objectForKey:uuid];
}

- (void)automountFavourites {
  for(RMFRamdisk *ramdisk in _favourites) {
    [self _observerRamdisk:ramdisk];
    if(ramdisk.isAutomount) {
      RMFMountController *mountController = [RMFMountController sharedController];
      [mountController mount:ramdisk];
    }
  }
}


- (void)_createUUIDDictionary {
  if(nil == _favourites) {
    _uuidToFavourites = [[NSMutableDictionary alloc] init];
  }
  else {
    self.uuidToFavourites = [NSMutableDictionary dictionaryWithCapacity:[_favourites count]];
  }
  for(RMFRamdisk *ramdisk in _favourites) {
    [_uuidToFavourites setObject:ramdisk forKey:ramdisk.uuid];
  }
}

- (void)_observerRamdisk:(RMFRamdisk *)ramdisk {
  if(ramdisk != nil) {
    // We register just for changes but do not care what changes happen
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForAutomount options:0 context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForBackupMode options:0 context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForLabel options:0 context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForSize options:0 context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForFinderLabelIndex options:0 context:nil];
    [ramdisk addObserver:self forKeyPath:kRMFRamdiskKeyForIsDefault options:0 context:nil];
  }
}

- (void)setDefaultRamdiskIndex:(NSInteger)defaultRamdiskIndex {
  if(_defaultRamdiskIndex != defaultRamdiskIndex) {
    RMFRamdisk *oldDefault = [self.favourites objectAtIndex:_defaultRamdiskIndex];
    RMFRamdisk *newDefault = [self.favourites objectAtIndex:defaultRamdiskIndex];
    if(oldDefault != nil && newDefault != nil) {
      newDefault.isDefault = YES;
      oldDefault.isDefault = NO;
      _defaultRamdiskIndex = defaultRamdiskIndex;
    }
  }
}

- (RMFRamdisk *)defaultRamdisk {
  RMFRamdisk *ramdisk = nil;
  @try {
    ramdisk = [_favourites objectAtIndex:_defaultRamdiskIndex];
  }
  @catch (NSException *exception) {
    NSLog(@"Warning. No default ramdisk found");
  }
  return ramdisk;
}

- (void)setDefaultRamdisk:(RMFRamdisk *)defaultRamdisk {
  [self willChangeValueForKey:kRMFFavouritesManagerFavouritesKeyForDefaultRamdisk];
  NSUInteger newIndex = [_favourites indexOfObject:defaultRamdisk];
  if(NSNotFound == newIndex) {
    return; // the new ramdisk is not valid
  }
  if(newIndex == _defaultRamdiskIndex) {
    return; // no change
  }
  RMFRamdisk *oldDefault = [_favourites objectAtIndex:_defaultRamdiskIndex];
  if(oldDefault != nil && oldDefault != defaultRamdisk) {
    oldDefault.isDefault = NO;
  }
  
  defaultRamdisk.isDefault = YES;
  self.defaultRamdiskIndex = newIndex;
  [self didChangeValueForKey:kRMFFavouritesManagerFavouritesKeyForDefaultRamdisk];
}

- (void)_validateDefaultRamdisk {
  
  assert([_favourites count] > 0);
  
  BOOL foundFavourite = NO;
  for(RMFRamdisk *ramdisk in _favourites) {
    if( ramdisk.isDefault && !foundFavourite) {
      foundFavourite = YES;
      _defaultRamdiskIndex = [_favourites indexOfObject:ramdisk];
    }
    else {
      ramdisk.isDefault = NO;
    }
  }
  if(!foundFavourite) {
    RMFRamdisk *ramdisk = [_favourites objectAtIndex:0];
    ramdisk.isDefault = YES;
    self.defaultRamdiskIndex = 0;
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

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if([object isKindOfClass:[RMFRamdisk class]]) {
    [self _synchronizeDefaults];
  }
}

- (void)_synchronizeDefaults {
  NSData *data= [NSKeyedArchiver archivedDataWithRootObject:_favourites];
  
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:kRMFSettingsKeyFavourites];
  [[NSUserDefaults standardUserDefaults] synchronize];
}



@end
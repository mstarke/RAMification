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
#import "RMFVolumeObserver.h"
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

- (BOOL)_addFavourite:(RMFRamdisk*) ramdisk;
- (RMFRamdisk *)_createUniqueFavourite;
- (void)_observerRamdisk:(RMFRamdisk *)ramdisk;
- (void)_createUUIDDictionary;
- (void)_synchronizeDefaults;
- (void)_validateDefaultRamdisk;

@end

// actual implementation
@implementation RMFFavouritesManager

#pragma mark convenience functions

+ (RMFFavouritesManager *)sharedManager {
  static RMFFavouritesManager *_sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[RMFFavouritesManager alloc] init];
  });
  return _sharedInstance;
}


#pragma mark object lifecycle

- (id)init {
  self = [super init];
  
  if (self) {
    NSLog(@"Trying to load presets!");
    self.defaultRamdiskIndex = NSNotFound;
    self.favourites = [NSMutableArray array];
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:RMFSettingsKeyFavourites];
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

#pragma mark preset handling

-(RMFRamdisk *)addNewFavourite {
  RMFRamdisk* ramdisk = [self _createUniqueFavourite];
  [self _addFavourite:ramdisk];
  return ramdisk;
}

- (NSArray *)mountedFavourites {
  return [_favourites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (RMFRamdisk *)_createUniqueFavourite {
  NSString *testpath = @"/Users/michael/Desktop/Test";
  NSString *unique = [NSString uniqueVolumeName:@"hallo" inFolder:testpath];
  NSLog(@"Unique Volume name: %@", unique);
  return [RMFRamdisk defaultRamdisk];
}

- (BOOL)_addFavourite:(RMFRamdisk *)ramdisk {
  BOOL isDuplicate = [_favourites containsObject:ramdisk];
  if(!isDuplicate) {
    [self insertObject:ramdisk inFavouritesAtIndex:[_favourites count]];
    _uuidToFavourites[ramdisk.uuid] = ramdisk;
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

- (RMFRamdisk *)findFavouriteWithVolumeURL:(NSURL *)url {
  if( [url isFileReferenceURL] ) {
    NSLog(@"%@: Error while searching for favourite by URL. Given URL %@ is nor fileRefrence URL", [self class], url);
    return nil;
  }
  
  for(RMFRamdisk *ramdisk in _favourites) {
    if([url isEqual:ramdisk.volumeURL]) {
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
  return _uuidToFavourites[uuid];
}

- (void)automountFavourites {
  for(RMFRamdisk *ramdisk in _favourites) {
    [self _observerRamdisk:ramdisk];
    if(ramdisk.isAutomount) {
      RMFMountController *mountController = [RMFMountController sharedController];
      [mountController mount:ramdisk autoskipCriticalSize:YES];
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
    _uuidToFavourites[ramdisk.uuid] = ramdisk;
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
    RMFRamdisk *oldDefault = (self.favourites)[_defaultRamdiskIndex];
    RMFRamdisk *newDefault = (self.favourites)[defaultRamdiskIndex];
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
    ramdisk = _favourites[_defaultRamdiskIndex];
  }
  @catch (NSException *exception) {
    NSLog(@"Warning. No default Ramdisk found");
  }
  return ramdisk;
}

- (void)setDefaultRamdisk:(RMFRamdisk *)defaultRamdisk {
  NSUInteger newIndex = [_favourites indexOfObject:defaultRamdisk];
  if(NSNotFound == newIndex) {
    return; // the new ramdisk is not valid
  }
  if(newIndex == _defaultRamdiskIndex) {
    return; // no change
  }
  RMFRamdisk *oldDefault = _favourites[_defaultRamdiskIndex];
  if(oldDefault != nil && oldDefault != defaultRamdisk) {
    oldDefault.isDefault = NO;
  }
  
  defaultRamdisk.isDefault = YES;
  self.defaultRamdiskIndex = newIndex;
}

- (void)_validateDefaultRamdisk {
  
  assert([_favourites count] > 0);
  
  BOOL foundFavourite = NO;
  for(RMFRamdisk *ramdisk in _favourites) {
    if( ramdisk.isDefault && !foundFavourite) {
      foundFavourite = YES;
      self.defaultRamdiskIndex = [_favourites indexOfObject:ramdisk];
    }
    else {
      ramdisk.isDefault = NO;
    }
  }
  if(!foundFavourite) {
    RMFRamdisk *ramdisk = _favourites[0];
    ramdisk.isDefault = YES;
    self.defaultRamdiskIndex = 0;
  }
}

# pragma mark KVC
- (void)removeObjectFromFavouritesAtIndex:(NSUInteger)index {
  [_favourites removeObjectAtIndex:index];
}

- (void)insertObject:(RMFRamdisk *)ramdisk inFavouritesAtIndex:(NSUInteger)index {
  [_favourites insertObject:ramdisk atIndex:index];
}

- (id)objectInFavouritesAtIndex:(NSUInteger)index {
  return _favourites[index];
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
  
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:RMFSettingsKeyFavourites];
  [[NSUserDefaults standardUserDefaults] synchronize];
}



@end
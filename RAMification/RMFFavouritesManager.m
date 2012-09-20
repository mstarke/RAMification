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

// private interface
@interface RMFFavouritesManager ()

@property (retain) NSMutableArray *favourites;

// Adds the given ramdisk to the favourites
// @param ramdisk favourite to add
// @return true if the favourite was added, false otherwise
- (BOOL) addFavourite:(RMFRamdisk*) ramdisk;
// creates a default favourite with a unique name
// @return the unique favourite
- (RMFRamdisk*) createUniqueFavourite;
// flushes changes to the preferences file
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
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:RMFSettingsKeyFavourites];
    if(data != nil) {
      NSArray *favourites = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if(favourites != nil) {
        self.favourites = [NSMutableArray arrayWithArray:favourites];
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
  return [self.favourites count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFRamdisk *favourite = [self.favourites objectAtIndex:row];
  // We need to wrap the identifier in a Number with bool to get the checkbox right
  if([tableColumn.identifier isEqualToString:RMFRamdiskKeyForAutomount]) {
    return [NSNumber numberWithBool:favourite.isAutomount];
  }
  return [favourite valueForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  RMFRamdisk *favourite = [self.favourites objectAtIndex:row];
  if([[tableColumn identifier] isEqualToString:RMFRamdiskKeyForSize]) {
    favourite.size = [object integerValue];
  }
  if([[tableColumn identifier] isEqualToString:RMFRamdiskKeyForAutomount]) {
    favourite.isAutomount = [object boolValue];
  }
  if([[tableColumn identifier] isEqualToString:RMFRamdiskKeyForLabel]) {
    NSString *oldLable = [NSString stringWithString:favourite.label];
    favourite.label = object;
    // Test for actual label change
    if(![oldLable isEqualToString:favourite.label]) {
      // as the mounter to rename the volume?
    }
    
  }
  if([[tableColumn identifier] isEqualToString:RMFRamdiskKeyForBackupMode]) {
    favourite.backupMode = [object intValue];
  }
  [self synchronizeDefaults];
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
  return [self.favourites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (BOOL) addFavourite:(RMFRamdisk *)ramdisk {
  BOOL isDuplicate = [self.favourites containsObject:ramdisk];
  if(!isDuplicate) {
    [self insertObject:ramdisk inFavouritesAtIndex:[self.favourites count]];
    [self synchronizeDefaults];
  } 
  return !isDuplicate;
}

- (void)deleteFavourite:(RMFRamdisk *)ramdisk {
  NSUInteger index = [self.favourites indexOfObject:ramdisk];
  [self removeObjectFromFavouritesAtIndex:index];
  [self synchronizeDefaults];
}

- (RMFRamdisk*) findFavouriteForName:(NSString*)name {
  for(RMFRamdisk *ramdisk in self.favourites) {
    if([ramdisk.label isEqualToString:name]) {
      return ramdisk;
    }
  }
  return nil;}

- (RMFRamdisk *)findFavouriteForDevicePath:(NSString *)path {
  for(RMFRamdisk *ramdisk in self.favourites) {
    if([ramdisk.devicePath isEqualToString:path]) {
      return ramdisk;
    }
  }
  return nil;
}

- (RMFRamdisk *)findFavouriteForBsdDevice:(NSString *)device {
  for(RMFRamdisk *ramdisk in self.favourites){
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
  for(RMFRamdisk *ramdisk in self.favourites) {
    if(ramdisk.isAutomount) {
      RMFMountController *mountController = [RMFMountController sharedController];
      [mountController mount:ramdisk];
    }
  }
}

# pragma mark KVC

- (void) removeObjectFromFavouritesAtIndex:(NSUInteger)index {
  [self.favourites removeObjectAtIndex:index];
}

- (void)insertObject:(RMFRamdisk *)ramdisk inFavouritesAtIndex:(NSUInteger)index {
  [self.favourites insertObject:ramdisk atIndex:index];
}

- (void)synchronizeDefaults {
  NSData *data= [NSKeyedArchiver archivedDataWithRootObject:self.favourites];
  
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:RMFSettingsKeyFavourites];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
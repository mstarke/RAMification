//
//  RMFPresetManager.m
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavoriteManager.h"

// add private write access to proterties
@interface RMFFavoriteManager ()

@property (retain) NSMutableSet *favourites;

@end

NSString *const RMFPresetsPreferencesKey = @"Favourites";

@implementation RMFFavoriteManager

@synthesize favourites = _favourites;

#pragma mark object lifecycle

- (id)init {
  self = [super init];
  if (self)
  {
    NSLog(@"Trying to load presets!");
    self.favourites = [NSMutableSet set];
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:RMFPresetsPreferencesKey];
    if(data != nil)
    {
      NSSet *favourites = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if(favourites != nil)
      {
        self.favourites = [NSMutableSet setWithSet:favourites];
      }
    }
  }
  return self;
}

- (void)dealloc {
  self.favourites = nil;
  [super dealloc];
}

#pragma mark NSTabelDataSource protocoll

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self.favourites count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return nil;
}

#pragma mark preset handling

- (RMFRamdisk *)createUniqueFavourite
{
  return [RMFRamdisk VolumePreset];
}

-(RMFRamdisk *)addNewFavourite
{
  RMFRamdisk* ramdisk = [self createUniqueFavourite];
  [self addFavourite:ramdisk];
  return ramdisk;
}

- (NSSet *)mountedFavourites
{
  return [self.favourites filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (BOOL) addFavourite:(RMFRamdisk *)ramdisk
{
  BOOL volumePresent = [self.favourites containsObject:ramdisk];
  if(!volumePresent)
  {
    [[self mutableSetValueForKey:@"favourites"] addObject:ramdisk];
    [self synchronizeDefaults];
  }
  
  return !volumePresent;
}

- (void)deleteFavourite:(RMFRamdisk *)preset
{
  [[NSApp delegate] unmountAndEjectDeviceAtPath:@""];
  [_favourites removeObject:preset];
}

- (void)updateFavourites
{
  // update favourites
}

- (void)synchronizeDefaults
{
  NSData *data= [NSKeyedArchiver archivedDataWithRootObject:self.favourites];
  
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:RMFPresetsPreferencesKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

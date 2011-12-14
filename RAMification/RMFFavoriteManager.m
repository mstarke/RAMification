//
//  RMFPresetManager.m
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavoriteManager.h"

NSString *const RMFPresetsPreferencesKey = @"Favourites";

@implementation RMFFavoriteManager

@synthesize favourites = _favourites;

#pragma mark object lifecycle

- (id)init {
  self = [super init];
  if (self)
  {
    NSLog(@"Trying to load presets!");
    _favourites = [[NSMutableArray array] retain];
    NSData *presetData = [[NSUserDefaults standardUserDefaults] dataForKey:RMFPresetsPreferencesKey];
    if(presetData != nil)
    {
      NSArray *presetArray = [NSKeyedUnarchiver unarchiveObjectWithData:presetData];
      if(presetArray != nil)
      {
        [_favourites release];
        _favourites = [[NSMutableArray arrayWithArray:presetArray] retain];
      }
    }
  }
  return self;
}

- (void)dealloc {
  [_favourites release];
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
  // todo implement
  return [RMFRamdisk VolumePreset];
}

-(RMFRamdisk *)addNewFavourite
{
  RMFRamdisk* newPreset = [self createUniqueFavourite];
  [self addFavourite:newPreset];
  return newPreset;
}

- (NSArray *)mountedPresets
{
  return [self.favourites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (BOOL) addFavourite:(RMFRamdisk *)ramdisk
{
  BOOL volumePresent = [_favourites containsObject:ramdisk];
  if(!ramdisk)
  {
    [_favourites addObject:ramdisk];
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

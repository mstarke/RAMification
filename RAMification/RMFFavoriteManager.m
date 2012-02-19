//
//  RMFPresetManager.m
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavoriteManager.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"

// add private write access to proterties
@interface RMFFavoriteManager ()

@property (retain) NSMutableArray *favourites;

@end


// actual implementation
@implementation RMFFavoriteManager

@synthesize favourites = _favourites;

#pragma mark object lifecycle

- (id)init {
  self = [super init];
  if (self)
  {
    NSLog(@"Trying to load presets!");
    self.favourites = [NSMutableArray array];
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:RMFSettingsKeyFavourites];
    if(data != nil)
    {
      NSArray *favourites = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if(favourites != nil)
      {
        self.favourites = [NSMutableArray arrayWithArray:favourites];
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
  RMFRamdisk *favourite = [self.favourites objectAtIndex:row];
  return [favourite valueForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  RMFRamdisk *favourite = [self.favourites objectAtIndex:row];
  if([tableColumn identifier] == RMFKeyForSize)
  {
    favourite.size = [object integerValue];
  }
  
  if([tableColumn identifier] == RMFKeyForAutomount)
  {
    favourite.automount = [object boolValue];
  }
  
  if([tableColumn identifier] == RMFKeyForLabel)
  {
    favourite.label = object;
  }
  
  [self synchronizeDefaults];
}


#pragma mark preset handling

- (RMFRamdisk *)createUniqueFavourite
{
  NSString *testpath = @"/Users/michael/Desktop/Test";
  NSString *unique = [NSString uniqueVolumeName:@"hallo" inFolder:testpath];
  return [RMFRamdisk VolumePreset];
}

-(RMFRamdisk *)addNewFavourite
{
  RMFRamdisk* ramdisk = [self createUniqueFavourite];
  [self addFavourite:ramdisk];
  return ramdisk;
}

- (NSArray *)mountedFavourites
{
  return [self.favourites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (BOOL) addFavourite:(RMFRamdisk *)ramdisk
{
  BOOL volumePresent = [self.favourites containsObject:ramdisk];
  if(!volumePresent)
  {
    [[self mutableArrayValueForKey:@"favourites"] addObject:ramdisk];
    [self synchronizeDefaults];
  }
  
  return !volumePresent;
}

- (void)deleteFavourite:(RMFRamdisk *)favourite
{
  [self.favourites removeObject:favourite];
  [self synchronizeDefaults];
}

- (void)updateFavourites
{
  // update favourites
}

- (void)synchronizeDefaults
{
  NSData *data= [NSKeyedArchiver archivedDataWithRootObject:self.favourites];
  
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:RMFSettingsKeyFavourites];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

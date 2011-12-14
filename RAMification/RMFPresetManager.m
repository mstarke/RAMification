//
//  RMFPresetManager.m
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFPresetManager.h"

@implementation RMFPresetManager

@synthesize presets = _presets;

#pragma mark class functions

+ (NSString *)presetsPreferencesKey
{
  return @"Presets";
}

#pragma mark object lifecycle

- (id)init {
  self = [super init];
  if (self)
  {
    NSLog(@"Trying to load presets!");
    _presets = [[NSMutableArray array] retain];
    NSData *presetData = [[NSUserDefaults standardUserDefaults] dataForKey:[RMFPresetManager presetsPreferencesKey]];
    if(presetData != nil)
    {
      NSArray *presetArray = [NSKeyedUnarchiver unarchiveObjectWithData:presetData];
      if(presetArray != nil)
      {
        [_presets release];
        _presets = [[NSMutableArray arrayWithArray:presetArray] retain];
      }
    }
  }
  return self;
}

- (void)dealloc {
  [_presets release];
  [super dealloc];
}

#pragma mark NSTabelDataSource protocoll

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self.presets count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return nil;
}

#pragma mark preset handling

- (RMFVolumePreset *)createUniqueVolumePreset
{
  // todo implement
  return [RMFVolumePreset VolumePreset];
}

-(RMFVolumePreset *)addNewVolumePreset
{
  RMFVolumePreset* newPreset = [self createUniqueVolumePreset];
  [self addVolumePreset:newPreset];
  return newPreset;
}

- (NSArray *)mountedPresets
{
  return [self.presets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isMounted == YES"]];
}

- (BOOL) addVolumePreset:(RMFVolumePreset *)preset
{
  BOOL volumePresent = [_presets containsObject:preset];
  if(!volumePresent)
  {
    [_presets addObject:preset];
    [self synchronize];
  }
  
  return !volumePresent;
}

- (void)deleteVolumePreset:(RMFVolumePreset *)preset
{
  [[NSApp delegate] unmountAndEjectDeviceAtPath:@""];
  [_presets removeObject:preset];
}

- (void)synchronize
{
  NSData *presetData = [NSKeyedArchiver archivedDataWithRootObject:self.presets];
  
  [[NSUserDefaults standardUserDefaults] setObject:presetData forKey:[RMFPresetManager presetsPreferencesKey]];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

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

+ (NSString *)presetsPreferencesKey
{
  return @"Presets";
}

- (id)init {
  self = [super init];
  if (self)
  {
    id loadedPrests = [[NSUserDefaults standardUserDefaults] arrayForKey:[RMFPresetManager presetsPreferencesKey]];
    if(loadedPrests != nil)
    {
      for(NSDictionary* volumeDict in loadedPrests)
      {
        RMFVolumePreset* preset = [RMFVolumePreset VolumePresetWithContentOfDict:volumeDict];
        if(preset != nil)
        {
          [_presets addObject:preset];
        }
      }
    }
    else
    {
      // we got no presets
    }
  }
  return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self.presets count];
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

- (void)synchronize
{
  // write out the preset to the defaults
  NSMutableArray *presetArray = [NSMutableArray array];
  for(RMFVolumePreset* preset in _presets)
  {
    [presetArray addObject:[preset convertToDictionary]];
  }
  [[NSUserDefaults standardUserDefaults] setValue:presetArray forKey:[RMFPresetManager presetsPreferencesKey]];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

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
    NSLog(@"Trying to load presets!");
    _presets = [[NSMutableArray array] retain];
    NSArray *loadedPresets = [[NSUserDefaults standardUserDefaults] arrayForKey:[RMFPresetManager presetsPreferencesKey]];
    if(loadedPresets != nil)
    {
      NSLog(@"Found %lu Presets", [loadedPresets count]);
      for(NSDictionary* volumeDict in loadedPresets)
      {
        RMFVolumePreset* preset = [RMFVolumePreset VolumePresetWithContentOfDict:volumeDict];
        if(preset != nil)
        {
          NSLog(@"Adding %@!", preset.volumeLabel);
          [_presets addObject:preset];
        }
      }
    }
  }
  return self;
}

- (void)dealloc {
  [_presets release];
  [super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self.presets count];
}

- (RMFVolumePreset *)createUniqueVolumePreset
{
  // todo implement
  return nil;
}

-(RMFVolumePreset *)addNewVolumePreset
{
  RMFVolumePreset* newPreset = [self createUniqueVolumePreset];
  [self addVolumePreset:newPreset];
  return [newPreset autorelease];
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

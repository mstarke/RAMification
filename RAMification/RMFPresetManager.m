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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self.presets count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  // todo
  return nil;
}

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

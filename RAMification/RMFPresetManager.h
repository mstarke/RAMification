//
//  RMFPresetManager.h
//  RAMification
//
//  Created by Michael Starke on 09.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMFVolumePreset.h"

@interface RMFPresetManager : NSObject <NSTableViewDataSource>

@property (readonly) NSMutableArray *presets;

+ (NSString*) presetsPreferencesKey;

- (BOOL) addVolumePreset:(RMFVolumePreset*) preset;
- (RMFVolumePreset*) addNewVolumePreset;
- (RMFVolumePreset*) createUniqueVolumePreset;
- (void) deleteVolumePreset:(RMFVolumePreset *)preset;
- (void) synchronize;


@end

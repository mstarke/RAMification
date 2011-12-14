//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFAppDelegate.h"
#import "RMFVolumePreset.h"
#import "RMFMountWatcher.h"

@implementation RMFAppDelegate

@synthesize mountedVolumes = _mountedVolumes;
@synthesize presetsManager = _presetsManager;
@synthesize settingsController = _settingsController;
@synthesize menuController = _menuController;
@synthesize mountWatcher = _mountWatcher;

# pragma mark object lifecycle

+ (void) initialize
{
  NSURL *defaultsPlistURL = [[NSBundle mainBundle] URLForResource:@"Defaults" withExtension:@"plist"];
  if(defaultsPlistURL != nil)
  {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:defaultsPlistURL]];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)dealloc
{
  self.settingsController = nil;
  self.mountedVolumes = nil;
  
  [super dealloc];
  // remove the toolbardelegate from the 
}

#pragma mark NSApplicationDelegate protocoll

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // initalize alle controller and the preset manager
  _settingsController = [[RMFSettingsController alloc] init];
  _presetsManager = [[RMFPresetManager alloc] init];
  _menuController = [[RMFMenuController alloc] init];
  _mountWatcher = [[RMFMountWatcher alloc] init];
}

@end

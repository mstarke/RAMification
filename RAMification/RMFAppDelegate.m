//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFAppDelegate.h"
#import "RMFVolumePreset.h"

@implementation RMFAppDelegate

@synthesize mountedVolumes = _mountedVolumes;
@synthesize presetsManager = _presetsManager;
@synthesize settingsController = _settingsController;
@synthesize menuController = _menuController;

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
}

//
// catch mount/unmounte events?
// NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
// NSNotificationCenter *center = [workspace notificationCenter];
//[center addObserver:[VolumeNotifier class] selector:@selector(volumeDidMount:) name:NSWorkspaceDidMountNotification object:nil];
//[center addObserver:[VolumeNotifier class] selector:@selector(volumeDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
//[center addObserver:[VolumeNotifier class] selector:@selector(volumeWillUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];


@end

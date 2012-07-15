//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFAppDelegate.h"
#import "RMFFavoriteManager.h"
#import "RMFSettingsController.h"
#import "RMFMenuController.h"
#import "RMFMountWatcher.h"
#import "RMFMountController.h"
#import "RMFSyncDaemon.h"

@interface RMFAppDelegate ()

@property (retain) RMFSettingsController *settingsController;
@property (retain) RMFFavoriteManager* favoritesManager;
@property (retain) RMFMenuController *menuController;
@property (retain) RMFMountWatcher *mountWatcher;
@property (retain) RMFMountController *mountController;
@property (retain) RMFSyncDaemon *syncDaemon;

@end


@implementation RMFAppDelegate

@synthesize favoritesManager = _favourtiesManager;
@synthesize settingsController = _settingsController;
@synthesize menuController = _menuController;
@synthesize mountWatcher = _mountWatcher;
@synthesize mountController = _mountController;
@synthesize syncDaemon = _syncDaemon;

# pragma mark object lifecycle

+ (void) initialize {
  NSURL *defaultsPlistURL = [[NSBundle mainBundle] URLForResource:@"Defaults" withExtension:@"plist"];
  if(defaultsPlistURL != nil) {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:defaultsPlistURL]];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)dealloc {
  self.settingsController = nil;  
  [super dealloc];
  
  // remove the toolbardelegate from the 
}

#pragma mark NSApplicationDelegate protocoll

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // initalize alle controller and the preset manager
  _settingsController = [[RMFSettingsController alloc] init];
  _favourtiesManager = [[RMFFavoriteManager alloc] init];
  _menuController = [[RMFMenuController alloc] init];
  _mountWatcher = [[RMFMountWatcher alloc] init];
  _mountController = [[RMFMountController alloc] init];
  _syncDaemon = [[RMFSyncDaemon alloc] init];
}

- (NSString *)executabelName {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
}

@end

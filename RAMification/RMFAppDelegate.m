//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFAppDelegate.h"

#import "RMFSettingsKeys.h"
#import "RMFFavouritesManager.h"
#import "RMFMenuController.h"
#import "RMFVolumeObserver.h"
#import "RMFSyncDaemon.h"
#import "RMFBufferDeamon.h"


@interface RMFAppDelegate ()

@property (retain) RMFMenuController *menuController;
@property (retain) RMFVolumeObserver *mountWatcher;
@property (retain) RMFSyncDaemon *syncDaemon;
@property (retain) RMFBufferDeamon *bufferDaemon;
@property (nonatomic, assign) BOOL canTerminateSuddenly;

@end


@implementation RMFAppDelegate

# pragma mark object lifecycle

+ (void) initialize {
  NSURL *defaultsPlistURL = [[NSBundle mainBundle] URLForResource:@"Defaults" withExtension:@"plist"];
  if(defaultsPlistURL != nil) {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:defaultsPlistURL]];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)dealloc {
  [super dealloc];
  // remove the toolbardelegate from the 
}

#pragma mark setter/getter
- (void)setCanTerminateSuddenly:(BOOL)canTerminateSuddenly {
  if(_canTerminateSuddenly != canTerminateSuddenly) {
    _canTerminateSuddenly = canTerminateSuddenly;
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    _canTerminateSuddenly ?  [processInfo enableSuddenTermination] : [processInfo disableSuddenTermination];
    NSString *statusString = _canTerminateSuddenly ? @"Enabled" : @"Disabled";
    NSLog(@"%@ sudden termination", statusString );
  }
}

#pragma mark NSApplicationDelegate protocoll
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
  /*
   Esablish defaults binding to ensure correct sudden termination behaviour
   */
  NSString *keyPath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyUnmountOnQuit];
  NSDictionary *bindingOptions = @{ NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName };
  [self bind:@"canTerminateSuddenly" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:keyPath options:bindingOptions];
  /*
   Initialize all Controllers and Daemons that work independently
   */
  _menuController = [[RMFMenuController alloc] init];
  _mountWatcher = [[RMFVolumeObserver alloc] init];
  _syncDaemon = [[RMFSyncDaemon alloc] init];
  _bufferDaemon = [[RMFBufferDeamon alloc] init];
  /*
   Look for mounted ramdisks and mount any automount favourites
   */  
  [_mountWatcher searchForMountedFavourites];
  [[RMFFavouritesManager sharedManager] automountFavourites];
}

- (NSString *)executabelName {
  return [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
}

#pragma mark NSUserNotificationCenterDelegate protocoll
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
  // We force all notifications to be displayed
  return YES;
}

@end

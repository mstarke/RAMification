//
//  AKPAppDelegate.m
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFAppDelegate.h"
#import "RMFFavouritesManager.h"
#import "RMFMenuController.h"
#import "RMFMountWatcher.h"
#import "RMFSyncDaemon.h"
#import "RMFBufferDeamon.h"

@interface RMFAppDelegate ()

@property (retain) RMFMenuController *menuController;
@property (retain) RMFMountWatcher *mountWatcher;
@property (retain) RMFSyncDaemon *syncDaemon;
@property (retain) RMFBufferDeamon *bufferDaemon;

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

#pragma mark NSApplicationDelegate protocoll

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  /*
   Initialize all Controllers and Daemons that work independently
   */
  _menuController = [[RMFMenuController alloc] init];
  _mountWatcher = [[RMFMountWatcher alloc] init];
  _syncDaemon = [[RMFSyncDaemon alloc] init];
  _bufferDaemon = [[RMFBufferDeamon alloc] init];
  
  [[RMFFavouritesManager sharedManager] initializeFavourites];
}

- (NSString *)executabelName {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
}

@end

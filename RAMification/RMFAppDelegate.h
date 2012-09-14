//
//  AKPAppDelegate.h
//  RAMification
//
//  Created by Michael Starke on 24.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RMFSettingsController;
@class RMFFavouritesManager;
@class RMFMenuController;
@class RMFMountWatcher;
@class RMFMountController;
@class RMFSyncDaemon;

@interface RMFAppDelegate : NSObject <NSApplicationDelegate>

@property (retain, readonly) RMFMountWatcher *mountWatcher;
@property (retain, readonly) RMFMountController *mountController;
@property (retain, readonly) RMFSyncDaemon *syncDaemon;

- (NSString *)executabelName;

@end
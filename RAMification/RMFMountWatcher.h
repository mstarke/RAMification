//
//  RMFMountWatcher.h
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

// Volume watcher reacts to changes in volume name and mounts/unmounts and tries to
// update and propagate all changes to the application to ensure a consistent state

APPKIT_EXTERN NSString *const RMFDidMountRamdiskNotification;
APPKIT_EXTERN NSString *const RMFDidUnmountRamdiskNotification;
APPKIT_EXTERN NSString *const RMFDidRenameRamdiskNotification;
APPKIT_EXTERN NSString *const kRMFMountWatcherRamdiskKey;
APPKIT_EXTERN NSString *const kRMFRamdiskLabelBeforeRenameKey;
APPKIT_EXTERN NSString *const kRMFRamdiskAlreadyMountedOnStartupKey;
APPKIT_EXTERN NSString *const kRMFRamdiskVolumeURLBeforeRenameKey;

@interface RMFMountWatcher : NSObject

+ (NSString *)bsdDeviceForVolumeAtURL:(NSURL *)volumeURL;
- (void)searchForMountedFavourites;

@end

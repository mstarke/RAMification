//
//  RMFMountWatcher.h
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 VolumeObserver reacts to changes in mounting and volumes and tries to
 update and propagate all changes to the application to ensure a consistent state
*/

/*
 Notification identifiers
 */
APPKIT_EXTERN NSString *const RMFVolumeObserverDidMountRamdiskNotification;
APPKIT_EXTERN NSString *const RMFVolumeObserverDidUnmountRamdiskNotification;
APPKIT_EXTERN NSString *const RMFVolumeObserverDidRenameRamdiskNotification;
APPKIT_EXTERN NSString *const RMFVolumeObserverDidCreateFileOnRamdiskNotification;
APPKIT_EXTERN NSString *const RMFVolumeObserverDidChangeFileAttributesNotification;

/*
 Acceskeys for the userInfo dicitionary attached to notifications
 */
APPKIT_EXTERN NSString *const RMFVolumeObserverRamdiskKey;
APPKIT_EXTERN NSString *const RMFVolumeObserverLabelBeforeRenameKey;
APPKIT_EXTERN NSString *const RMFVolumeObserverWasAlreadyMountedOnStartupKey;
APPKIT_EXTERN NSString *const RMFVolumeObserverVolumeURLBeforeRenameKey;
APPKIT_EXTERN NSString *const RMFVolumeObserverPathOfCreatedFileOnRamdiskKey;


@interface RMFVolumeObserver : NSObject

+ (NSString *)bsdDeviceForVolumeAtURL:(NSURL *)volumeURL;
- (void)searchForMountedFavourites;

@end

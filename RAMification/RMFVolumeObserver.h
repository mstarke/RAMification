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
APPKIT_EXTERN NSString *const RMFDidMountRamdiskNotification;
APPKIT_EXTERN NSString *const RMFDidUnmountRamdiskNotification;
APPKIT_EXTERN NSString *const RMFDidRenameRamdiskNotification;
APPKIT_EXTERN NSString *const RMFDidCreateFileOnRamdiskNotification;
APPKIT_EXTERN NSString *const RMFDidChangeFileAttributesNotification;

/*
 Acceskeys for the userInfo dicitionary attached to notifications
 */
APPKIT_EXTERN NSString *const kRMFRamdiskKey;
APPKIT_EXTERN NSString *const kRMFRamdiskLabelBeforeRenameKey;
APPKIT_EXTERN NSString *const kRMFRamdiskAlreadyMountedOnStartupKey;
APPKIT_EXTERN NSString *const kRMFRamdiskVolumeURLBeforeRenameKey;
APPKIT_EXTERN NSString *const kRMFPathOfCreatedFileOnRamdiskKey;


@interface RMFVolumeObserver : NSObject

+ (NSString *)bsdDeviceForVolumeAtURL:(NSURL *)volumeURL;
- (void)searchForMountedFavourites;

@end

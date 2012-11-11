//
//  RMFFileEventsWatcher.h
//  RAMification
//
//  Created by michael starke on 11.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

APPKIT_EXTERN NSString *const RMFDidCreateFileOnRamdiskNotification;
APPKIT_EXTERN NSString *const RMFDidChangeRamdiskFinderLabelNotification;

@interface RMFFileEventsWatcher : NSObject

@end

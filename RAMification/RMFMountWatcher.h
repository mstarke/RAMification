//
//  RMFMountWatcher.h
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
/* Mount Watchter listens to all mount/unmount notifications */
@interface RMFMountWatcher : NSObject

- (void) volumeDidMount:(NSNotification*)notification;
- (void) volumeDidUnmount:(NSNotification*)notification;
- (void) volumeWillUnmount:(NSNotification*)notification;

@end

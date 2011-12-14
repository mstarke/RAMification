//
//  RMFMountWatcher.h
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMFMountWatcher : NSObject

- (void) volumeDidMount:(NSString*)devicePath;
- (void) volumeDidUnmount:(NSString*)devicePath;
- (void) volumeWillUnmount:(NSString*)devicePath;

@end

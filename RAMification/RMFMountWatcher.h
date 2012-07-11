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
@interface RMFMountWatcher : NSObject

@end

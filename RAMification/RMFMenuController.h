//
//  RMFMenuController.h
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMFMenuController : NSObject

- (void) quitApplication;
- (void) removeRamdisk;
- (void) showSettingsTab:(id)sender;
- (void) setHibernateWarningVisible:(BOOL)isVisible;

@end

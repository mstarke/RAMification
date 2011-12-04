//
//  RMFDefaultSettingsContoller.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsControllerProtocol.h"

@interface RMFGeneralSettingsController : NSViewController <RMFSettingsControllerProtocol>

- (IBAction) toggleLaunchAtLogin:(id)sender;

@end

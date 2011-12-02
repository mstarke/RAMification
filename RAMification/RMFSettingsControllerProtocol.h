//
//  RMFSettingsControllerProtocol.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RMFSettingsControllerProtocol <NSObject>

@required

+ (NSString*) identifier;
+ (NSString*) label;
+ (NSToolbarItem*) toolbarItem;

@end

//
//  RMFDefaultSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFGeneralSettingsContoller.h"

@implementation RMFGeneralSettingsContoller

+ (NSString *) identifier
{
  return @"GeneralSettings";
}

+ (NSString *) label
{
  return NSLocalizedString(@"GENERAL_SETTINGS_LABEL", @"Label for the General Settings");
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:@"GeneralSettings" bundle:[NSBundle mainBundle]];
  if (self)
  {
    // init
  }
    
    return self;
}

@end

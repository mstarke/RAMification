//
//  RMFFavouriteCellView.m
//  RAMification
//
//  Created by michael starke on 06.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouriteCellView.h"

NSString *const kRMFFavouriteCellViewKeyForIsDefault = @"isDefault";

@implementation RMFFavouriteCellView

- (void)setIsDefault:(NSNumber *)isDefault {
  [self willChangeValueForKey:kRMFFavouriteCellViewKeyForIsDefault];
  
  
  if( _isDefault == nil ) {
    _isDefault = [[NSNumber alloc] initWithBool:NO];
  }
  
  if([self.isDefault boolValue] == [isDefault boolValue]) {
    return; // no changes
  }
  else {
    [_isDefault autorelease];
    _isDefault = [isDefault retain];
  }
  
  NSFont *labelFont = [_lableTextField font];
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  
  NSFontTraitMask traitMask = [isDefault boolValue] ? NSBoldFontMask : NSUnboldFontMask;
  
  labelFont = [fontManager convertFont:labelFont toHaveTrait:traitMask];
  [_lableTextField setFont:labelFont];
  
  [self didChangeValueForKey:kRMFFavouriteCellViewKeyForIsDefault];
}

@end

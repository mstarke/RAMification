//
//  RMFFavouriteCellView.m
//  RAMification
//
//  Created by michael starke on 06.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouriteCellView.h"

@implementation RMFFavouriteCellView


- (NSNumber *)isDefault {
  NSFont *labelFont = [_lableTextField font];
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFontTraitMask traitMask = [fontManager traitsOfFont:labelFont];
  BOOL isDefault = ((traitMask & NSFontItalicTrait) != 0);
  
  return [NSNumber numberWithBool:isDefault];
}

- (void)setIsDefault:(NSNumber *)isDefault {
  BOOL newDefault = [isDefault boolValue];
  if([self.isDefault boolValue] == newDefault) {
    return; // no changes
  }
  
  NSFont *labelFont = [_lableTextField font];
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  
  NSFontTraitMask traitMask = newDefault ? NSFontItalicTrait : NSUnitalicFontMask;
  
  labelFont = [fontManager convertFont:labelFont toHaveTrait:traitMask];
  [_lableTextField setFont:labelFont];
}

@end

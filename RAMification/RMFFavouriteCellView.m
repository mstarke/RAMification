//
//  RMFFavouriteCellView.m
//  RAMification
//
//  Created by michael starke on 06.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouriteCellView.h"

#import "RMFLabelTextField.h"

NSString *const kRMFFavouriteCellViewKeyForIsDefault = @"isDefault";

@implementation RMFFavouriteCellView

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if(self) {
    _isDefault = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self) {
    _isDefault = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isDefault))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeBool:self.isDefault forKey:NSStringFromSelector(@selector(isDefault))];
}

- (void)setIsDefault:(BOOL)isDefault {
  
  if(self.isDefault == isDefault) {
    return; // no changes
  }
  else {
    _isDefault = isDefault;
  }
  
  NSFont *labelFont = [_lableTextField font];
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  
  NSFontTraitMask traitMask = self.isDefault ? NSBoldFontMask : NSUnboldFontMask;
  
  labelFont = [fontManager convertFont:labelFont toHaveTrait:traitMask];
  [_lableTextField setFont:labelFont];
}

@end

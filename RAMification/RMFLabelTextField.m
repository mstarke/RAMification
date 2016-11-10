//
//  RMFLabelTextField.m
//  RAMification
//
//  Created by michael starke on 09.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFLabelTextField.h"

NSString *const kRMFLabelTextFieldFinderLabelIndexKey = @"finderLabelIndex";
NSUInteger static const kRMFLabelTextFieldCornderRadius = 6.0;

static NSRect RMFRectWithLabel(const NSRect rect) {
  const CGFloat fShift = 0.5 * kRMFLabelTextFieldCornderRadius;
  return NSMakeRect(rect.origin.x - fShift
                    , rect.origin.y - fShift
                    , rect.size.width + fShift
                    , rect.size.height + fShift);
}
static NSRect RMFRectWithoutLabel(const NSRect rect) {
  const CGFloat fShift = 0.5 * kRMFLabelTextFieldCornderRadius;
  return NSMakeRect(rect.origin.x + fShift
                            , rect.origin.y + fShift
                            , rect.size.width - fShift
                            , rect.size.height - fShift);
}
@implementation RMFLabelTextField

- (void)drawRect:(NSRect)dirtyRect
{
  const NSRect originalFrame = self.frame;
  const NSRect drawRect = self.bounds;
  if(_finderLabelIndex != 0) {
    const NSRect adjustedRect = NSMakeRect(drawRect.origin.x + .5, drawRect.origin.y + .5, drawRect.size.width - 1, drawRect.size.height - 1);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:adjustedRect xRadius:kRMFLabelTextFieldCornderRadius yRadius:kRMFLabelTextFieldCornderRadius];
    
    NSColor *lableColor = [self finderLabelColor];
    NSGradient *fillGradient = [[NSGradient alloc] initWithStartingColor:[lableColor highlightWithLevel:0.5] endingColor:lableColor];
    [fillGradient drawInBezierPath:path angle:90.0];
    [[lableColor shadowWithLevel:0.2] setStroke];
    [path stroke];
    self.frame = RMFRectWithoutLabel(self.frame);
    [self setNeedsDisplay:YES];
  }
  [super drawRect:dirtyRect];
  self.frame = originalFrame;
}

- (NSColor *)finderLabelColor {
  if(_finderLabelIndex == 0) {
    return [NSColor clearColor]; // No lable so no color
  }
  NSArray *labelColors = [NSWorkspace sharedWorkspace].fileLabelColors;
  NSColor *color = nil;
  @try {
    color = labelColors[_finderLabelIndex];
  }
  @catch (NSException *exception) {
    color = [NSColor clearColor];
    NSLog(@"%@", exception);
  }
  return color;
}

- (void)setFinderLabelIndex:(NSUInteger)finderLabelIndex {
  if(_finderLabelIndex == finderLabelIndex) {
    return; // no changes necessary
  }
  // shift frame left if are using labels now
  if(_finderLabelIndex == 0) {
    self.frame = RMFRectWithLabel(self.frame);
  }
  // shift back if label was removed
  else if(finderLabelIndex == 0) {
    self.frame = RMFRectWithoutLabel(self.frame);
  }
  _finderLabelIndex = finderLabelIndex;
  [self setNeedsDisplay:YES];
}

@end


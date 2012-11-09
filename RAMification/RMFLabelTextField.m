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

@implementation RMFLabelTextField

- (void)drawRect:(NSRect)dirtyRect
{
  NSRect outlineRect = NSMakeRect(dirtyRect.origin.x - 1.0, dirtyRect.origin.y - 1.0, dirtyRect.size.width + 2.0, dirtyRect.size.height + 2.0);
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:kRMFLabelTextFieldCornderRadius yRadius:kRMFLabelTextFieldCornderRadius];
  //NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:outlineRect xRadius:kRMFLabelTextFieldCornderRadius + 1.0 yRadius:kRMFLabelTextFieldCornderRadius + 1.0];
  NSColor *lableColor = [self finderLabelColor];
  if(NO == [lableColor isEqual:[NSColor clearColor]]) {
    NSGradient *fillGradient = [[NSGradient alloc] initWithStartingColor:[lableColor highlightWithLevel:0.2] endingColor:[lableColor shadowWithLevel:0.2]];
    [fillGradient drawInBezierPath:path angle:90.0];
    [fillGradient release];
  }
  [super drawRect:dirtyRect];
}

- (NSColor *)finderLabelColor {
  if(_finderLabelIndex == 0) {
    return [NSColor clearColor]; // No lable so no color
  }
  NSArray *labelColors = [[NSWorkspace sharedWorkspace] fileLabelColors];
  NSColor *color = nil;
  @try {
    color = [labelColors objectAtIndex:_finderLabelIndex];
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
  [self willChangeValueForKey:kRMFLabelTextFieldFinderLabelIndexKey];
  _finderLabelIndex = finderLabelIndex;
  [self setNeedsDisplay:YES];
  [self didChangeValueForKey:kRMFLabelTextFieldFinderLabelIndexKey];

}

@end


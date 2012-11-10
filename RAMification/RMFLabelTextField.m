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
  NSRect adjustedRect = NSMakeRect(dirtyRect.origin.x + .5, dirtyRect.origin.y + .5, dirtyRect.size.width - 1, dirtyRect.size.height - 1);
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:adjustedRect xRadius:kRMFLabelTextFieldCornderRadius yRadius:kRMFLabelTextFieldCornderRadius];
  NSColor *lableColor = [self finderLabelColor];
  NSRect myFrame = [self frame];
  if(NO == [lableColor isEqual:[NSColor clearColor]]) {
    NSGradient *fillGradient = [[NSGradient alloc] initWithStartingColor:[lableColor highlightWithLevel:0.5] endingColor:lableColor];
    [fillGradient drawInBezierPath:path angle:90.0];
    [fillGradient release];
    [[lableColor shadowWithLevel:0.2] setStroke];
    [path stroke];
    [self setFrame:NSMakeRect(myFrame.origin.x + kRMFLabelTextFieldCornderRadius
                              , myFrame.origin.y
                              , myFrame.size.width - kRMFLabelTextFieldCornderRadius
                              , myFrame.size.height)];
    [self setNeedsDisplay:YES];
  }
  [super drawRect:dirtyRect];
  [self setFrame:myFrame];
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


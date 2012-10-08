//
//  RMFFavouritesArrayControllerDelegate.m
//  RAMification
//
//  Created by michael starke on 08.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouritesArrayControllerDelegate.h"
#import "RMFArrayController.h"

@implementation RMFFavouritesArrayControllerDelegate

- (BOOL)canRemoveWithArrayController:(RMFArrayController *)arrayController {
  NSInteger selectionIndex = [arrayController selectionIndex];
  return (selectionIndex != NSNotFound && selectionIndex != 0);
}

@end

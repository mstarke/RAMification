//
//  RMFArrayController.m
//  RAMification
//
//  Created by michael starke on 08.10.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFArrayController.h"

@implementation RMFArrayController

- (id)init {
  self = [super init];
  if (self) {
    self.delegate = nil;
  }
  return self;
}

- (BOOL)canAdd {
  if(nil != _delegate) {
    if ([_delegate respondsToSelector:@selector(canAddWithArrayController:)]) {
      return [_delegate canAddWithArrayController:self];
    }
  }
  return [super canAdd];
}

- (BOOL)canRemove {
  if(nil != _delegate) {
    if([_delegate respondsToSelector:@selector(canRemoveWithArrayController:)]) {
      return [_delegate canRemoveWithArrayController:self];
    }
  }
  return [super canInsert];
}

- (BOOL)canInsert {
  if(nil != _delegate) {
    if([_delegate respondsToSelector:@selector(canInsertWithArrayController:)]) {
      return [_delegate canInsertWithArrayController:self];
    }
  }
  return [super canRemove];
}

@end

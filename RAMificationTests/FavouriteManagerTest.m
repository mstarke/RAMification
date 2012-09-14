//
//  FavouriteManagerTest.m
//  RAMification
//
//  Created by Michael Starke on 13.07.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "FavouriteManagerTest.h"

#import "RMFFavouritesManager.h"

@implementation FavouriteManagerTest

- (void)setUp {
  [super setUp];
  favouriteManager = [[RMFFavouritesManager alloc] init];
}

- (void)tearDown {
  [favouriteManager release];
  [super tearDown];
}

@end

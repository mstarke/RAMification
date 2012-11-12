//
//  RMFChangedMountedFavouriteCellView.m
//  RAMification
//
//  Created by michael starke on 06.11.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFChangedMountedFavouriteCellView.h"

#import "RMFChangedMountedFavouritesController.h"

@implementation RMFChangedMountedFavouriteCellView

- (void)awakeFromNib {
  [_actionSelectionControl setSegmentCount:RMFChangedFavouriteActionCount];
  
  NSDictionary *images = @{
  @(RMFChangedFavouriteIgnoreAction) : [NSImage imageNamed:NSImageNameStopProgressTemplate],
  @(RMFChangedFavouriteRevertVolume) : [[NSBundle mainBundle] imageForResource:@"UpdateVolumeTemplate"],
  @(RMFChangedFavouriteUpdateFavourite): [[NSBundle mainBundle] imageForResource:@"UpdateFavouriteTemplate"]
  };

  NSDictionary *toolTips = @{
  @(RMFChangedFavouriteIgnoreAction) : NSLocalizedString(@"FAVOURITE_NAME_CHANGED_ACTION_IGNORE", @"Ignore name changes"),
  @(RMFChangedFavouriteRevertVolume) : NSLocalizedString(@"FAVOURITE_NAME_CHANGED_ACTION_UPDATE_FAVOURITE", @"Update the favourite"),
  @(RMFChangedFavouriteUpdateFavourite) : NSLocalizedString(@"FAVOURITE_NAME_CHANGED_ACTION_UPDATE_VOLUME", @"Update the volume")
  };

  for(NSNumber *key in [images allKeys]) {
    NSUInteger segmentIndex = [key integerValue];
    [[_actionSelectionControl cell] setToolTip:toolTips[key] forSegment:segmentIndex];
    [_actionSelectionControl setImage:images[key] forSegment:segmentIndex];
  }
}

@end

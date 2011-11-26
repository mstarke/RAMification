//
//  SettingsToolbarDelegate.m
//  RAMification
//
//  Created by Michael Starke on 25.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSettingsController.h"


@implementation RMFSettingsController

// TODO implement toolbar programatically
// insert tabs by loading nibs
// set identifiers programatically
// to make selection work transparent

@synthesize tabView;
@synthesize toolbar;
@synthesize settingsWindow;

- (id)init
{
  self = [super init];
  if (self)
  {
    settingsTabNames = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:RMFGeneralTab], RMFGeneral,
                        [NSNumber numberWithInt:RMFPresetsTab], RMFPresets,
                        nil];  
    
    // just if there are really two tabs change their identifiers and headings
    if([self.tabView numberOfTabViewItems] == 2)
    {
      [self.tabView tabViewItemAtIndex:0].label = RMFGeneral;
      [self.tabView tabViewItemAtIndex:0].identifier = RMFGeneral;
      [self.tabView tabViewItemAtIndex:1].label = RMFPresets;
      [self.tabView tabViewItemAtIndex:1].identifier = RMFPresets;
    }
    [self.toolbar setSelectedItemIdentifier:RMFGeneral];
    [self.tabView selectTabViewItemWithIdentifier:RMFGeneral];
  }
  return self;
}

- (NSArray*) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
  return nil;
  return [NSArray arrayWithObjects:RMFGeneral, RMFPresets, nil];
}


- (IBAction) switchTabView:(id)sender
{
  //NSString *label = [(NSToolbarItem*)sender label];
  //NSLog(@"Select %@", label);
  [tabView selectTabViewItemWithIdentifier:[toolbar selectedItemIdentifier]];
}

- (void) showWindow
{
  [self.settingsWindow setIsVisible:YES];
}


NSString *const RMFGeneral = @"General";
NSString *const RMFPresets = @"Presets";

@end

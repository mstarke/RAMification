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


@synthesize settingsWindow;
@synthesize toolbar = _toolbar;
@synthesize presetSettingsController = _presetSettingsController;
@synthesize generalSettingsController = _generalSettingsController;

- (id)init
{
  self = [super init];
  if (self)
  {
    // load the window and create all the necessary gui elements
    [NSBundle loadNibNamed:@"SettingsWindow" owner:self];
    
    // Initalize the controllers
    _generalSettingsController = [[RMFGeneralSettingsContoller alloc] initWithNibName:nil bundle:nil];
    _presetSettingsController = [[RMFPresetSettingsContoller alloc] initWithNibName:nil bundle:nil];
    
    //Fixme let the views controller handle this
    availableSettingsControler = [NSDictionary dictionaryWithObjectsAndKeys:_generalSettingsController,
                                                                            [RMFGeneralSettingsContoller identifier],
                                                                            _presetSettingsController,
                                                                            [RMFPresetSettingsContoller identifier], nil];
    // create the necessary toolbar delgate
    toolbarDelegate = [[RMFSettingsToolbarDelegate alloc] init];
    
    _toolbar = [[NSToolbar alloc] initWithIdentifier:@"SettingsToolbar"];
    self.toolbar.delegate = toolbarDelegate;
    self.settingsWindow.toolbar = _toolbar;
    // just if there are really two tabs change their identifiers and headings
  }
  return self;
}

- (void)dealloc
{
  self.toolbar = nil;
  [toolbarDelegate dealloc];
  [super dealloc];
}

- (void) showWindowWithActiveTab:(NSString *)tabidentifier
{
  if(tabidentifier != nil)
  {
    // select the tab
    //[self.toolbar setSelectedItemIdentifier:tabidentifier];
    //[self.tabView selectTabViewItemWithIdentifier:tabidentifier];
  }
  [self.settingsWindow setIsVisible:YES];
}

- (void) showWindow
{
  [self showWindowWithActiveTab:nil];
}

@end

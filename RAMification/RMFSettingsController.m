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
    _generalSettingsController = [[RMFGeneralSettingsController alloc] initWithNibName:nil bundle:nil];
    _presetSettingsController = [[RMFPresetSettingsController alloc] initWithNibName:nil bundle:nil];
    
    //Fixme let the views controller handle this
    settingsPaneControler = [[NSDictionary alloc] initWithObjectsAndKeys:_generalSettingsController,
                                                                        [RMFGeneralSettingsController identifier],
                                                                        _presetSettingsController,
                                                                        [RMFPresetSettingsController identifier], nil];
    
    _toolbar = [[NSToolbar alloc] initWithIdentifier:@"SettingsToolbar"];
    self.toolbar.allowsUserCustomization = YES;
    self.toolbar.delegate = self;
    self.settingsWindow.toolbar = _toolbar;
    // just if there are really two tabs change their identifiers and headings
  }
  return self;
}

- (void)dealloc
{
  self.toolbar = nil;
  [settingsPaneControler release];
  [super dealloc];
}

- (void)showSettings:(id)sender
{
  NSString* settingsIdentifier;
  
  if([sender isMemberOfClass:[NSToolbarItem class]])
  {
    settingsIdentifier = [(NSToolbarItem*)sender itemIdentifier];
  }
  else
  {
    if ([sender isKindOfClass:[NSString class]])
    {
      settingsIdentifier = sender;
    }
  }
 
  if(sender == nil)
  {
    settingsIdentifier = [RMFGeneralSettingsController identifier];
  }
  id<RMFSettingsControllerProtocol> visibleSettings = [settingsPaneControler objectForKey:settingsIdentifier];
  
  if(visibleSettings == nil)
  {
    visibleSettings = _generalSettingsController;
  }
  [self.toolbar setSelectedItemIdentifier:[[visibleSettings class] identifier]];
  NSView *settingsView = [(NSViewController*)visibleSettings view];
  //[self.settingsWindow setContentSize:[settingsView frame].size];
  [self.settingsWindow setContentView:settingsView];
  [self.settingsWindow setIsVisible:YES];
}

#pragma mark NSToolbarDelegateProtocol

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
  return [settingsPaneControler allKeys];
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
  return [settingsPaneControler allKeys];
}

- (NSArray *) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
  return [settingsPaneControler allKeys];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
  id controller = [settingsPaneControler objectForKey:itemIdentifier];
  NSToolbarItem *item = [[controller class ]toolbarItem];
  [item setAction:@selector(showSettings:)];
  [item setTarget:self];
  return item;
}

@end

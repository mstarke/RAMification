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
@synthesize generalTab;
@synthesize presetsTab;

- (id)init
{
  self = [super init];
  if (self)
  {
    // intialize the defauls values
    [self intializeDefaults];
    // load the window and create all the necessary gui elements
    [NSBundle loadNibNamed:@"SettingsWindow" owner:self];
    settingsTabNames = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:RMFGeneralTab], RMFGeneralIdentifier,
                        [NSNumber numberWithInt:RMFPresetsTab], RMFPresetsIdentifier,
                        nil];  
    
    // just if there are really two tabs change their identifiers and headings
    NSTabViewItem *generalTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:RMFGeneralIdentifier];
    NSTabViewItem *presetTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:RMFPresetsIdentifier];
    
    [NSBundle loadNibNamed:@"GeneralTab" owner:self];
    [NSBundle loadNibNamed:@"PresetsTab" owner:self];
    
    [generalTabViewItem setView:self.generalTab];
    [presetTabViewItem setView:self.presetsTab];
    
    [tabView addTabViewItem:generalTabViewItem];
    [tabView addTabViewItem:presetTabViewItem];

    [self.toolbar setSelectedItemIdentifier:RMFGeneralIdentifier];
    [self.tabView selectTabViewItemWithIdentifier:RMFGeneralIdentifier];
    
    [generalTabViewItem release];
    [presetTabViewItem release];
  }
  return self;
}

- (NSArray*) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
  return nil;
  return [NSArray arrayWithObjects:RMFGeneralIdentifier, RMFPresetsIdentifier, nil];
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

- (void) intializeDefaults
{
  NSDictionary *defaultPreset = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"ShouldAutoMount",
                                                                            [NSNumber numberWithUnsignedInt:1024], @"VolumeSize",
                                                                            @"RAMdisk",@"VolumeLabel",
                                                                            nil]; 
  NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"LaunchAtLogin",
                                                                                [NSArray arrayWithObject:defaultPreset], @"Presets",
                                                                                nil];
  
  [defaultsDictionary writeToFile:@"/Users/michael/Desktop/export.plist" atomically:YES];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
  [[NSUserDefaults standardUserDefaults] synchronize];
}



NSString *const RMFGeneralIdentifier = @"General";
NSString *const RMFPresetsIdentifier = @"Presets";

@end

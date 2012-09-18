//  RAMification
//
//  Created by Michael Starke on 25.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFSettingsController.h"

#import "RMFAppDelegate.h"

#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/ps/IOPowerSources.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSString *const kHiberNateModeKey = @"Hibernate Mode";
NSString *const kIOKitPowerManagementCurrentSettingsPath = @"State:/IOKit/PowerManagement/CurrentSettings";

static RMFSettingsController *sharedSingleton;

@interface RMFSettingsController ()

@property (retain) RMFGeneralSettingsController *generalSettingsController;
@property (retain) RMFFavoritesSettingsController *presetSettingsController;
@property (retain) NSToolbar* toolbar;
@property (retain) NSDictionary *paneController;
@property (assign) NSUInteger hibernateMode;
@property (retain) NSView *emptyView;

- (void) readHibernateMode;

@end


@implementation RMFSettingsController

+ (void)initialize {
  static BOOL initialized = NO;
  if(!initialized) {
    initialized = YES;
    sharedSingleton = [[RMFSettingsController alloc] init];
  }
}

+ (RMFSettingsController *)sharedController {
  return sharedSingleton;
}

# pragma mark object lifecycle

- (id)init {
  self = [super init];
  if (self) {
    // load the window and create all the necessary gui elements
    [NSBundle loadNibNamed:@"SettingsWindow" owner:self];
    
    // Initalize the controllers
    _generalSettingsController = [[RMFGeneralSettingsController alloc] initWithNibName:nil bundle:nil];
    _presetSettingsController = [[RMFFavoritesSettingsController alloc] initWithNibName:nil bundle:nil];
    
    _paneController = [[NSDictionary alloc] initWithObjectsAndKeys:_generalSettingsController,
                                                                        [RMFGeneralSettingsController identifier],
                                                                        _presetSettingsController,
                                                                        [RMFFavoritesSettingsController identifier], nil];
    
    _toolbar = [[NSToolbar alloc] initWithIdentifier:@"SettingsToolbar"];
    self.toolbar.allowsUserCustomization = YES;
    self.toolbar.delegate = self;
    self.settingsWindow.toolbar = _toolbar;
    _emptyView = [[NSView alloc] init];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  self.toolbar = nil;
  self.paneController = nil;
  self.generalSettingsController = nil;
  self.presetSettingsController = nil;
  [super dealloc];
}

#pragma mark actions

- (void)showSettings:(id)sender {
  NSString* settingsIdentifier = nil;
  
  // the call can originate from a NSMenuItem or a NSToolbarItem
  // the NSMenuItem just sends a identifier string as sender
  // the NSToolbarItem delivers itself as the sender
  //
  // We get a NSToolbarItem
  if([sender isMemberOfClass:[NSToolbarItem class]]) {
    settingsIdentifier = [(NSToolbarItem*)sender itemIdentifier];
  }
  // or the otherwise, we collect the string.
  else {
    if ([sender isKindOfClass:[NSString class]]) {
      settingsIdentifier = sender;
    }
  }
  
  // if something went wrong, we go for the defautl identitifer (first tab)
  if(sender == nil) {
    settingsIdentifier = [RMFGeneralSettingsController identifier];
  }
  id<RMFSettingsControllerProtocol> visibleSettings = [_paneController objectForKey:settingsIdentifier];
  
  if(visibleSettings == nil) {
    visibleSettings = _generalSettingsController;
  }
  // highlight the toolbar item
  [self.toolbar setSelectedItemIdentifier:[[visibleSettings class] identifier]];
  NSView *settingsView = [(NSViewController*)visibleSettings view];
  // remove the old content view to store it's size
  [self.settingsWindow setContentView:_emptyView];
  NSRect windowRect = [_settingsWindow frameRectForContentRect:[settingsView frame]];
  windowRect.origin.x = [_settingsWindow frame].origin.x;
  windowRect.origin.y = [_settingsWindow frame].origin.y + [_settingsWindow frame].size.height - windowRect.size.height;
  [_settingsWindow setFrame:windowRect display:YES animate:YES];
  //[self.settingsWindow setContentSize:[settingsView frame].size];
  // set the new view
  [_settingsWindow setContentView:settingsView];
  // and show the window, if already visible this doesn't hurt.
  [_settingsWindow setIsVisible:YES];
}

#pragma mark system env retrieval

- (void) readHibernateMode {
  SCDynamicStoreRef dynamicStore = SCDynamicStoreCreate(NULL, CFSTR("ramification"), NULL, NULL);
  // read current settings from SCDynamicStore key
  CFPropertyListRef liveValues = SCDynamicStoreCopyValue(dynamicStore, (CFStringRef)kIOKitPowerManagementCurrentSettingsPath);
  if(!liveValues) {
    return; // The values return is NULL
  }
  NSDictionary *valuesDict = liveValues;
  self.hibernateMode = [[valuesDict objectForKey:kHiberNateModeKey] intValue];
  CFRelease(liveValues);
  CFRelease(dynamicStore);
}

#pragma mark NSToolbarDelegateProtocol

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  return [_paneController allKeys];
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return [_paneController allKeys];
}

- (NSArray *) toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return [_paneController allKeys];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  id controller = [_paneController objectForKey:itemIdentifier];
  NSToolbarItem *item = [[controller class ]toolbarItem];
  [item setAction:@selector(showSettings:)];
  [item setTarget:self];
  return item;
}

@end

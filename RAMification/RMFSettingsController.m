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

@interface RMFSettingsController ()

@property (retain) RMFGeneralSettingsController *generalSettingsController;
@property (retain) RMFFavouritesSettingsController *favouriteSettingsController;
@property (retain) NSToolbar* toolbar;
@property (retain) NSDictionary *paneController;
@property (assign) NSUInteger hibernateMode;
@property (retain) NSView *emptyView;

- (void) readHibernateMode;

@end


@implementation RMFSettingsController

+ (RMFSettingsController *)sharedController {
  static RMFSettingsController *_sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[RMFSettingsController alloc] init];
  });
  return _sharedInstance;
}

# pragma mark object lifecycle
- (id)init {
  self = [super init];
  if (self) {
    // load the window and create all the necessary gui elements
    [NSBundle loadNibNamed:@"SettingsWindow" owner:self];
    // Initalize the controllers
    _generalSettingsController = [[RMFGeneralSettingsController alloc] initWithNibName:nil bundle:nil];
    _favouriteSettingsController = [[RMFFavouritesSettingsController alloc] initWithNibName:nil bundle:nil];
    
    // Setup the controllermap
    self.paneController = @{ [RMFGeneralSettingsController identifier] : _generalSettingsController, [RMFFavouritesSettingsController identifier] : _favouriteSettingsController };
    
    _toolbar = [[NSToolbar alloc] initWithIdentifier:@"SettingsToolbar"];
    self.toolbar.allowsUserCustomization = NO;
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
  self.favouriteSettingsController = nil;
  [super dealloc];
}

#pragma mark actions
- (void)showSettings:(id)sender {
  /*
   Prevent any changes if the icon selection is visible
   */
  if([_favouriteSettingsController.iconSelectionWindow isVisible]) {
    return;
  }
  /*
   the call can originate from a NSMenuItem or a NSToolbarItem
   the NSMenuItem just sends a identifier string as sender
   the NSToolbarItem delivers itself as the sender
   */
  
  NSString* settingsIdentifier = nil;
  if([sender isMemberOfClass:[NSToolbarItem class]]) {
    settingsIdentifier = [(NSToolbarItem*)sender itemIdentifier];
  }
  else {
    if ([sender isKindOfClass:[NSString class]]) {
      settingsIdentifier = sender;
    }
    else {
      settingsIdentifier = [RMFGeneralSettingsController identifier];
    }
  }
  
  id<RMFSettingsTabController> visibleSettings = _paneController[settingsIdentifier];
  
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
  
  [_settingsWindow setContentView:settingsView];
  [_settingsWindow setTitle:[[visibleSettings class ]label]];
  [_settingsWindow setIsVisible:YES];
  [_settingsWindow makeKeyAndOrderFront:self];
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
  self.hibernateMode = [valuesDict[kHiberNateModeKey] intValue];
  
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
  id controller = _paneController[itemIdentifier];
  NSToolbarItem *item = [[controller class ]toolbarItem];
  [item setAction:@selector(showSettings:)];
  [item setTarget:self];
  return item;
}

@end

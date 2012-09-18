//
//  RMFMenuController.m
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFMenuController.h"

#import "RMFRamdisk.h"
#import "RMFFavouritesManager.h"
#import "RMFAppDelegate.h"
#import "RMFCreateRamDiskOperation.h"
#import "RMFSettingsController.h"
#import "RMFMountController.h"
#import "RMFMountWatcher.h"
#import "NSString+RMFVolumeTools.h"

NSString *const RMFMenuIconTemplateImage = @"MenuItemIconTemplate";
NSString *const RMFFavouritesManagerFavourites = @"favourites";
NSString *const RMFRamDiskLabel = @"label";
NSString *const RMFRamDiskIsDirty = @"isDirty";
const NSUInteger RMFFavouritesMenuIndexOffset = 2;

@interface RMFMenuController ()
@property (retain) NSMenuItem *noFavouritesMenuItem;
@property (retain) NSMenuItem *hibernateWarningMenuItem;
@property (retain) NSMenu *menu;
@property (retain) NSMenu *favoritesMenu;
@property (retain) NSStatusItem *statusItem;
@property (retain) NSOperationQueue *queue;
@property (retain) NSMutableDictionary *menuItemsToFavouritesMap;

// creates the status item to be inserted in the menu bar
- (void) createStatusItem;
// creates the menu that is added to the status item
- (void) createMenu;
// create the inital favourites menu
- (void) createFavouritesMenu;
// adds a menu item for the given favourite
- (BOOL) addFavouriteMenuItem:(RMFRamdisk *)favourite atEnd:(BOOL)atEnd;
// adds a liste of favourites to the menu
- (BOOL) addFavouriteMenuItems:(NSArray *)favourites atEnd:(BOOL)atEnd;
// removes a list of favouriest from the menu
- (void) removeFavouriteMenuItems:(NSArray *)favourites;
// removes the menu item associated with this favourite
- (BOOL) removeFavouriteMenuItem:(RMFRamdisk *)favourite;
// adds a info note that there are not favourites
- (void) addNoFavouritesWarningAtEnd:(BOOL)atEnd;
// updates the menu item represneting this favourite
- (void) updateFavourite:(RMFRamdisk *)favourite;
// callback to for a single favourite menu item
- (void) handleFavouriteClicked:(id)sender;
// Updates the menuitem to the changes in the ramdisk
- (void) updateMenuItem:(NSMenuItem *)item ramDisk:(RMFRamdisk *)ramDisk;

- (void)ramDiskChanged:(NSNotification *)notification;

@end


@implementation RMFMenuController

#pragma mark object lifecycle
- (id)init {
  self = [super init];
  if (self) {
    _menuItemsToFavouritesMap = [[NSMutableDictionary alloc] init];
    [self createMenu];
    [self createStatusItem];
    RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
    [favouritesManager addObserver:self forKeyPath:RMFFavouritesManagerFavourites options:( NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld ) context:nil];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(ramDiskChanged:) name:RMFDidMountRamdiskNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(ramDiskChanged:) name:RMFDidUnmountRamdiskNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(ramDiskChanged:) name:RMFDidRenameRamdiskNotification object:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  self.noFavouritesMenuItem = nil;
  self.hibernateWarningMenuItem = nil;
  self.menuItemsToFavouritesMap = nil;
  self.menu = nil;
  self.favoritesMenu = nil;
  self.statusItem = nil;
  self.queue = nil;
  self.menuItemsToFavouritesMap = nil;
  [super dealloc];
}

# pragma mark create/update menu

- (void)createFavouritesMenu {
  RMFFavouritesManager *manager = [RMFFavouritesManager sharedManager];
  _favoritesMenu = [[NSMenu alloc] initWithTitle:@"PresetsSubmenu"];
  
  for(RMFRamdisk *favorite in manager.favourites) {
    [self addFavouriteMenuItem:favorite atEnd:YES];
  }
  
  if([manager.favourites count] == 0) {
    [self addNoFavouritesWarningAtEnd:YES];
  }
  [_favoritesMenu addItem:[NSMenuItem separatorItem]];
}

- (void) createMenu
{
  _menu = [[NSMenu alloc] initWithTitle:@"menu"];
  NSMenuItem *item;
  
  // About
  NSString *appName = [((RMFAppDelegate *)[NSApp delegate]) executabelName];
  NSString *aboutString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"MENU_ABOUT", @"The lolcalized Version of About"), appName];
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aboutString action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:NSApp];
  [_menu addItem:item];
  [item release];
  
  // Preferences
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"MENU_ITEM_PREFERENCES", @"Menu Item - Preferences")] action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFGeneralSettingsController identifier]];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [_menu addItem:item];
  // add to map!
  [item release];
  
  [_menu addItem:[NSMenuItem separatorItem]];
  
  // Create ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"MENU_CREATE_RAMDISK", @"Create Ramdisk") action:@selector(handleFavouriteClicked:) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [_menu addItem:item];
  [item release];
  
  // Destroy ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"MENU_UNMOUNT_RAMDISK", @"Destroy Ramdisk") action:@selector(removeRamdisk) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [_menu addItem:item];
  [item release];
  
  // Favourites
  [self createFavouritesMenu];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"MENU_MANAGE_FAVOURITES", @"Menu Manage Favourites")] action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFFavoritesSettingsController identifier]];
  [item setEnabled:YES];
  [item setTarget:self];
  [_favoritesMenu addItem:item];
  [item release];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"COMMON_PLURAL_FAVOURITE", @"Favourites") action:nil keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [item setSubmenu:self.favoritesMenu];
  [_menu addItem:item];
  [item release];
  
  // Separation
  [_menu addItem:[NSMenuItem separatorItem]];
  
  // Quit
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"COMMON_QUIT", @"Quit") action:@selector(quitApplication) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [self.menu addItem:item];
  [item release];
  
  RMFSettingsController *settingsController = [RMFSettingsController sharedController];
  BOOL shouldDisplayWarning = ( [settingsController hibernateMode] != 0);
  [self setHibernateWarningVisible:shouldDisplayWarning];
}

- (void) createStatusItem {
  NSStatusBar *bar = [NSStatusBar systemStatusBar];
  self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
  NSImage *menuIconImage = [NSImage imageNamed:RMFMenuIconTemplateImage];
  [_statusItem setImage:menuIconImage];
  [_statusItem setEnabled:YES];
  [_statusItem setHighlightMode:YES];
  [_statusItem setMenu:self.menu];
}

# pragma mark Favourite Menu updates

- (BOOL)addFavouriteMenuItems:(NSArray *)favourites atEnd:(BOOL)atEnd {
  BOOL didAddAllItems = YES;
  for( RMFRamdisk *disk in favourites ) {
    didAddAllItems &= [self addFavouriteMenuItem:disk atEnd:atEnd];
  }
  return didAddAllItems;
}

- (void)addNoFavouritesWarningAtEnd:(BOOL)atEnd {
  if(self.noFavouritesMenuItem == nil) {
    _noFavouritesMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                             initWithTitle:NSLocalizedString(@"MENU_NO_FAVOURITES_DEFINED", @"Menu Item - No Favourites defined")
                             action:NULL
                             keyEquivalent:@""];
    
  }
  NSInteger index = atEnd ? [self.favoritesMenu numberOfItems] : [self.favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
  NSArray *indexArray = [NSArray arrayWithObjects:[NSNumber numberWithInteger:index], [NSNumber numberWithInt:0], nil];
  NSNumber *minimum = [indexArray valueForKeyPath:@"@min.intValue"];
  [self.favoritesMenu insertItem:self.noFavouritesMenuItem atIndex:[minimum integerValue]];
}

- (BOOL)addFavouriteMenuItem:(RMFRamdisk *)favorite atEnd:(BOOL)atEnd {
  NSValue *favouriteId = [NSValue valueWithNonretainedObject:favorite];
  if( [[self.menuItemsToFavouritesMap allValues] containsObject:favouriteId] ) {
    return FALSE; // The item is already present
  }
  else {
    // We need to add a new menu item
    if ( self.noFavouritesMenuItem != nil && [[_favoritesMenu itemArray] containsObject:self.noFavouritesMenuItem]) {
      [self.favoritesMenu removeItem:self.noFavouritesMenuItem];
    }
    
    NSUInteger index = atEnd ? [_favoritesMenu numberOfItems] : [_favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                        initWithTitle:favorite.label
                        action:@selector(handleFavouriteClicked:)
                        keyEquivalent:@""];
    // Add ourselves as observer for label changes on the favourite
    [favorite addObserver:self forKeyPath:RMFRamDiskLabel options:0 context:item];
    [favorite addObserver:self forKeyPath:RMFRamDiskIsDirty options:0 context:item];
    [item setTarget:self];
    [_favoritesMenu insertItem:item atIndex:index];
    [_menuItemsToFavouritesMap setObject:[NSValue valueWithNonretainedObject:favorite] forKey:[NSValue valueWithNonretainedObject:item]];
    [item release];
    
    return TRUE;
  }
}

- (void)updateMenuItem:(NSMenuItem *)item ramDisk:(RMFRamdisk *)ramDisk {
  if( [[_favoritesMenu itemArray] containsObject:item] ) {
    [item setTitle:ramDisk.label];
    ramDisk.isMounted ? [item setState:NSOnState] : [item setState:NSOffState];
  }
}

- (void) removeFavouriteMenuItems:(NSArray *)favourites {
  for(RMFRamdisk *disk in favourites) {
    [self removeFavouriteMenuItem:disk];
  }
}

- (BOOL) removeFavouriteMenuItem:(RMFRamdisk *)favourite {
  NSValue *favouriteId = [NSValue valueWithNonretainedObject:favourite];
  NSValue *itemId = [[_menuItemsToFavouritesMap allKeysForObject:favouriteId] lastObject];
  if(itemId != nil) {
    // remove all key-value-observer from the removed ramdisk
    [favourite removeObserver:self forKeyPath:RMFRamDiskLabel];
    [favourite removeObserver:self forKeyPath:RMFRamDiskIsDirty];
    NSMenuItem *item = [itemId nonretainedObjectValue];
    [_favoritesMenu removeItem:item];
    [_menuItemsToFavouritesMap removeObjectForKey:itemId];
    
    // Menu is empty
    if([_menuItemsToFavouritesMap count] == 0) {
      [self addNoFavouritesWarningAtEnd:NO];
    }
    
    return YES;
  }
  return NO;
}

# pragma mark actions

- (void) quitApplication {
  //Unmount ramdisk?
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) showSettingsTab:(id)sender {
  RMFSettingsController *settingsController = [RMFSettingsController sharedController];
  [settingsController showSettings:[sender representedObject]];
}

- (void)handleFavouriteClicked:(id)sender {
  NSMenuItem* item = sender;
  NSValue *presetId = [_menuItemsToFavouritesMap objectForKey:[NSValue valueWithNonretainedObject:item]];
  RMFRamdisk* ramdisk = [presetId nonretainedObjectValue];
  [[RMFMountController sharedController] toggleMounted:ramdisk];
}

- (void)updateFavourite:(RMFRamdisk *)favourite {
  NSValue *itemId = [[_menuItemsToFavouritesMap allKeysForObject:[NSValue valueWithNonretainedObject:favourite]] lastObject];
  NSMenuItem *item = [itemId nonretainedObjectValue];
  [item setTitle:favourite.label];
  NSInteger state = favourite.isMounted ? NSOnState : NSOffState;
  [item setState:state];
}

- (void) removeRamdisk {
  [_queue cancelAllOperations];
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
}

- (void)setHibernateWarningVisible:(BOOL)isVisible {
  BOOL isWarningVisible = [[_menu itemArray] containsObject:_hibernateWarningMenuItem];
  // current status does not match intended one
  if(isVisible != isWarningVisible) {
    // if we need to display the menu, we must fist make sure it's there.
    if( isVisible ) {
      if (_hibernateWarningMenuItem == nil) {
        _hibernateWarningMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                                     initWithTitle:NSLocalizedString(@"MENU_WRONG_HIBERNATE_MODE", @"Menu Item - Current Hibernate mode causes ram disk to be unmounted after wake-up from sleep")
                                     action:NULL
                                     keyEquivalent:@""];
      }
      [_menu insertItem:[NSMenuItem separatorItem] atIndex:0];
      [_menu insertItem:_hibernateWarningMenuItem atIndex:0];
    }
    else {
      if([[_menu itemAtIndex:0] isSeparatorItem]) {
        [_menu removeItemAtIndex:0];
      }
      [_menu removeItem:_hibernateWarningMenuItem];
    }
  }
}

# pragma mark Notifications
- (void)ramDiskChanged:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  RMFRamdisk *ramdisk = [userInfo objectForKey:RMFRamdiskKey];
  if(ramdisk == nil) {
    return; // no ramdisk sent
  }
  [self updateFavourite:ramdisk];
}


# pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if( [keyPath isEqualToString:RMFRamDiskLabel] || [keyPath isEqualToString:RMFRamDiskIsDirty] ) {
    if( [object isMemberOfClass:[RMFRamdisk class]] ) {
      RMFRamdisk *ramDisk = (RMFRamdisk *)object;
      NSMenuItem *item = context;
      [self updateMenuItem:item ramDisk:ramDisk];
      return;
    }
  }
  if( [keyPath isEqualToString:RMFFavouritesManagerFavourites] ) {
    NSUInteger changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
    switch (changeKind) {
      case NSKeyValueChangeInsertion: {
        NSArray *insertedItems = [change objectForKey:NSKeyValueChangeNewKey];
        [self addFavouriteMenuItems:insertedItems atEnd:NO];
      }
      case NSKeyValueChangeRemoval: {
        
        NSArray *removedItems = [change objectForKey:NSKeyValueChangeOldKey];
        [self removeFavouriteMenuItems:removedItems];
        break;
      }
    }
    return;
  }
}
@end

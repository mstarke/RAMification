//
//  RMFMenuController.m
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFMenuController.h"

#import "RMFRamdisk.h"
#import "RMFFavoriteManager.h"
#import "RMFAppDelegate.h"
#import "RMFCreateRamDiskOperation.h"
#import "RMFSettingsController.h"
#import "RMFMountController.h"
#import "NSString+RMFVolumeTools.h"

NSString *const RMFMenuIconTemplateImage = @"MenuItemIconTemplate";
NSString *const RMFFavouritesManagerFavourites = @"favourites";
NSString *const RMFRamDiskLabel = @"label";
NSString *const RMFRamDiskIsDirty = @"isDirty";
const NSUInteger RMFFavouritesMenuIndexOffset = 2;

@interface RMFMenuController ()

// creates the status item to be inserted in the menu bar 
- (void) createStatusItem;
// creates the menu that is added to the status item
- (void) createMenu;
// create the inital favourites menu
- (void) createFavouritesMenu;
- (BOOL) addFavouriteMenuItem:(RMFRamdisk *)favourite atEnd:(BOOL)atEnd;
- (BOOL) addFavouriteMenuItems:(NSArray *)favourites atEnd:(BOOL)atEnd;
- (void) removeFavouriteMenuItems:(NSArray *)favourites;
- (BOOL) removeFavouriteMenuItem:(RMFRamdisk *)favourite;
// adds a info note that there are not favourites
- (void) addNoFavouritesInfoAtEnd:(BOOL)atEnd;
// updates the menu item represneting this favourite
- (void) updateFavourite:(RMFRamdisk *)favourite;
// callback to for a single favourite menu item
- (void) handleFavouriteClicked:(id)sender;

// Updates the menuitem to the changes in the ramdisk
// @param item MenuItem to update
// @param ramDisk Updated ramDisk
- (void) updateMenuItem:(NSMenuItem *)item ramDisk:(RMFRamdisk *)ramDisk;

@end


@implementation RMFMenuController

#pragma mark object lifecycle
- (id)init {
  self = [super init];
  if (self) {
    favouritesToMenuItemsMap = [[NSMutableDictionary alloc] init];
    [self createMenu];
    [self createStatusItem];
    [((RMFAppDelegate*)[NSApp delegate]).favoritesManager addObserver:self
                                                           forKeyPath:RMFFavouritesManagerFavourites
                                                              options:( NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld )
                                                              context:nil];
  }
  return self;
}

- (void)dealloc {
  [statusItem release];
  [menu release];
  favouritesToMenuItemsMap = nil;
  
  statusItem = nil;
  menu = nil;
  
  [super dealloc];
}

# pragma mark create/update menu

- (void)createFavouritesMenu {
  RMFFavoriteManager *manager = ((RMFAppDelegate*)[NSApp delegate]).favoritesManager;
  favoritesMenu = [[NSMenu alloc] initWithTitle:@"PresetsSubmenu"];
  
  for(RMFRamdisk *favorite in manager.favourites) {
    [self addFavouriteMenuItem:favorite atEnd:YES];
  }
  
  if([manager.favourites count] == 0) {
    [self addNoFavouritesInfoAtEnd:YES];
  }
  [favoritesMenu addItem:[NSMenuItem separatorItem]];
}

- (void) createMenu
{
  menu = [[NSMenu alloc] initWithTitle:@"menu"];
  NSMenuItem *item;
  
  // About
  NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
  NSString *aboutString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"MENU_ABOUT", @"The lolcalized Version of About"), appName];
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aboutString action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:NSApp];
  [menu addItem:item];
  [item release];
  
  // Preferences
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"MENU_ITEM_PREFERENCES", @"Menu Item - Preferences")] action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFGeneralSettingsController identifier]];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [menu addItem:item];
  // add to map!
  [item release];
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  // Create ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"MENU_CREATE_RAMDISK", @"Create Ramdisk") action:@selector(handleFavouriteClicked:) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [menu addItem:item];
  [item release];
  
  // Destroy ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"MENU_UNMOUNT_RAMDISK", @"Destroy Ramdisk") action:@selector(removeRamdisk) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item setTarget:self];
  [menu addItem:item];
  [item release];
  
  // Favourites
  [self createFavouritesMenu];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@...", NSLocalizedString(@"MENU_MANAGE_FAVOURITES", @"Menu Manage Favourites")] action:@selector(showSettingsTab:) keyEquivalent:@""];
  [item setRepresentedObject:[RMFFavoritesSettingsController identifier]];
  [item setEnabled:YES];
  [item setTarget:self];
  [favoritesMenu addItem:item];
  [item release];
  
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"COMMON_PLURAL_FAVOURITE", @"Favourites") action:nil keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [item setSubmenu:favoritesMenu];
  [menu addItem:item];
  [item release];
  
  // Separation
  [menu addItem:[NSMenuItem separatorItem]];
  
  // Quit
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"COMMON_QUIT", @"Quit") action:@selector(quitApplication) keyEquivalent:@""];
  [item setEnabled:YES];
  [item setTarget:self];
  [menu addItem:item];
  [item release];
}

- (void) createStatusItem {
  NSStatusBar *bar = [NSStatusBar systemStatusBar];
  statusItem = [[bar statusItemWithLength:NSVariableStatusItemLength] retain];
  NSImage *menuIconImage = [NSImage imageNamed:RMFMenuIconTemplateImage];
  [statusItem setImage:menuIconImage];
  [statusItem setEnabled:YES];
  [statusItem setHighlightMode:YES];
  [statusItem setMenu:menu];
}

# pragma mark Favourite Menu updates

- (BOOL)addFavouriteMenuItems:(NSArray *)favourites atEnd:(BOOL)atEnd {
  BOOL didAddAllItems = YES;
  for( RMFRamdisk *disk in favourites ) {
    didAddAllItems &= [self addFavouriteMenuItem:disk atEnd:atEnd];
  }
  return didAddAllItems;
}

- (void)addNoFavouritesInfoAtEnd:(BOOL)atEnd {
  NSInteger index = atEnd ? [favoritesMenu numberOfItems] : [favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
  NSArray *indexArray = [NSArray arrayWithObjects:[NSNumber numberWithInteger:index], [NSNumber numberWithInt:0], nil];
  NSNumber *minimum = [indexArray valueForKeyPath:@"@min.intValue"];
  NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                      initWithTitle:NSLocalizedString(@"MENU_NO_FAVOURITES_DEFINED", @"Menu Item - No Favourites defined")
                      action:nil
                      keyEquivalent:@""];
  [favoritesMenu insertItem:item atIndex:[minimum integerValue]];
  [item release];
}

- (BOOL)addFavouriteMenuItem:(RMFRamdisk *)favorite atEnd:(BOOL)atEnd {
  // The item is already present
  if( [[favouritesToMenuItemsMap allValues] containsObject:favorite] ) {
    return FALSE;
  }
  // New item needs to be created and added to the menu
  else {
    NSUInteger index = atEnd ? [favoritesMenu numberOfItems] : [favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                        initWithTitle:favorite.label
                        action:@selector(handleFavouriteClicked:)
                        keyEquivalent:@""];
    // Add ourselves as observer for label changes on the favourite
    [favorite addObserver:self forKeyPath:RMFRamDiskLabel options:0 context:item];
    [favorite addObserver:self forKeyPath:RMFRamDiskIsDirty options:0 context:item];
    [item setTarget:self];
    [favoritesMenu insertItem:item atIndex:index];
    [favouritesToMenuItemsMap setObject:[NSValue valueWithNonretainedObject:favorite] forKey:[NSValue valueWithNonretainedObject:item]];
    [item release];
    
    return TRUE;
  }
} 

- (void)updateMenuItem:(NSMenuItem *)item ramDisk:(RMFRamdisk *)ramDisk {
  if( [[favoritesMenu itemArray] containsObject:item] ) {
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
  NSValue *itemId = [[favouritesToMenuItemsMap allKeysForObject:favouriteId] lastObject];
  if(itemId != nil) {
    // remove all key-value-observer from the removed ramdisk
    [favourite removeObserver:self forKeyPath:RMFRamDiskLabel];
    [favourite removeObserver:self forKeyPath:RMFRamDiskIsDirty];
    NSMenuItem *item = [itemId nonretainedObjectValue];
    [favoritesMenu removeItem:item];
    [favouritesToMenuItemsMap removeObjectForKey:favouriteId];
    
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
  [((RMFAppDelegate*)[NSApp delegate]).settingsController showSettings:[sender representedObject]];
}

- (void)handleFavouriteClicked:(id)sender {
  NSMenuItem* item = sender;
  NSValue *presetId = [favouritesToMenuItemsMap objectForKey:[NSValue valueWithNonretainedObject:item]];
  RMFRamdisk* ramdisk = [presetId nonretainedObjectValue];
  RMFAppDelegate* delegate = [NSApp delegate];
  RMFMountController* mountController = delegate.mountController;
  [mountController toggleMounted:ramdisk];
}

- (void) updateFavourite:(RMFRamdisk *)favourite {
  NSValue *itemId = [[favouritesToMenuItemsMap allKeysForObject:[NSValue valueWithNonretainedObject:favourite]] lastObject];
  NSMenuItem *item = [itemId nonretainedObjectValue];
  [item setTitle:favourite.label];
}

- (void) removeRamdisk {
  [queue cancelAllOperations];
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
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

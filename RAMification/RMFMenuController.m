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
#import "NSString+RMFVolumeTools.h"

NSString *const RMFMenuIconTemplateImage = @"MenuItemIconTemplate";
NSString *const RMFFavouritesManagerFavourites = @"favourites";
NSString *const RMFRamDiskLabel = @"label";
const NSUInteger RMFFavouritesMenuIndexOffset = 2;

@interface RMFMenuController ()

- (BOOL) addFavouriteMenuItem:(RMFRamdisk *)favourite atEnd:(BOOL)atEnd;
/* creates the status item to be inserted in the menu bar */
- (void) createStatusItem;
/* creates the menu that is added to the status item*/
- (void) createMenu;
/* create the inital favourites menu */
- (void) createFavouritesMenu;
/* adds a info note that there are not favourites */
- (void) addNoFavouritesInfoAtEnd:(BOOL)atEnd;
/* updates the favourites menu for new additions */
- (void) updateFavouritesMenu;
/* updates the menu item represneting this favourite */
- (void) updateFavourite:(RMFRamdisk *)favourite;
/* callback to for a single favourite menu item */
- (void) updateFavouriteState:(id)sender;


@end


@implementation RMFMenuController

#pragma mark object lifecycle
- (id)init
{
  self = [super init];
  if (self)
  {
    queue = [[NSOperationQueue alloc] init];
    favouritesToMenuItemsMap = [[NSMutableDictionary alloc] init];
    [self createMenu];
    [self createStatusItem];
    [((RMFAppDelegate*)[NSApp delegate]).favoritesManager addObserver:self
                                                           forKeyPath:RMFFavouritesManagerFavourites
                                                              options:0
                                                              context:nil];
  }
  return self;
}

- (void)dealloc {
  [queue release];
  [statusItem release];
  [menu release];
  [favouritesToMenuItemsMap release];
  
  queue = nil;
  statusItem = nil;
  menu = nil;
  favouritesToMenuItemsMap = nil;
  
  [super dealloc];
}

# pragma mark create/update menu

- (void)createFavouritesMenu
{
  RMFFavoriteManager *manager = ((RMFAppDelegate*)[NSApp delegate]).favoritesManager;
  favoritesMenu = [[NSMenu alloc] initWithTitle:@"PresetsSubmenu"];
  
  for(RMFRamdisk *favorite in manager.favourites)
  {
    [self addFavouriteMenuItem:favorite atEnd:YES];
  }
  
  if([manager.favourites count] == 0)
  {
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
  [item release];
  
  [menu addItem:[NSMenuItem separatorItem]];
  
  // Create ramdisk
  item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"MENU_CREATE_RAMDISK", @"Create Ramdisk") action:@selector(updateFavouriteState:) keyEquivalent:@""];
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

- (void) createStatusItem
{
  NSStatusBar *bar = [NSStatusBar systemStatusBar];
  statusItem = [[bar statusItemWithLength:NSVariableStatusItemLength] retain];
  NSImage *menuIconImage = [NSImage imageNamed:RMFMenuIconTemplateImage];
  [statusItem setImage:menuIconImage];
  [statusItem setEnabled:YES];
  [statusItem setHighlightMode:YES];
  [statusItem setMenu:menu];
}

- (void)addNoFavouritesInfoAtEnd:(BOOL)atEnd
{
  NSUInteger index = atEnd ? [favoritesMenu numberOfItems] : [favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
  NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                      initWithTitle:NSLocalizedString(@"MENU_NO_FAVOURITES_DEFINED", @"Menu Item - No Favourites defined")
                      action:nil
                      keyEquivalent:@""];
  [favoritesMenu insertItem:item atIndex:index];
  [item release];
}

- (BOOL)addFavouriteMenuItem:(RMFRamdisk *)favorite atEnd:(BOOL)atEnd {
  
  // The item is already present
  if( [[favouritesToMenuItemsMap allValues] containsObject:favorite] ) {
    return FALSE;
  }
  // New item needs to be created and added to the menu
  else
  {
    NSUInteger index = atEnd ? [favoritesMenu numberOfItems] : [favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                        initWithTitle:favorite.label
                        action:@selector(updateFavouriteState:)
                        keyEquivalent:@""];
    // Add ourselves as observer for label changes on the favourite
    [favorite addObserver:self forKeyPath:RMFRamDiskLabel options:0 context:nil];
    [item setTarget:self];
    [favoritesMenu insertItem:item atIndex:index];
    [favouritesToMenuItemsMap setObject:[NSValue valueWithNonretainedObject:favorite] forKey:[NSValue valueWithNonretainedObject:item]];
    [item release];
    
    return TRUE;
  }
} 


- (void)updateFavouritesMenu
{
  // Holds all the current menu items so we find obsolete ones
  NSMutableSet *validItems= [NSMutableSet setWithCapacity:[favouritesToMenuItemsMap count]];
  RMFAppDelegate *delegate = [NSApp delegate];
  RMFFavoriteManager *favouriteManager = delegate.favoritesManager;
  for( RMFRamdisk *ramdisk in favouriteManager.favourites )
  {
    if( [[favouritesToMenuItemsMap allValues] containsObject:[NSValue valueWithNonretainedObject:ramdisk]] )
    {
      // Favourite is in the menu so just mark it as updated
      NSValue *itemId = [[favouritesToMenuItemsMap allKeysForObject:[NSValue valueWithNonretainedObject:ramdisk]] lastObject];
      [validItems addObject:itemId];
    }
    else
    {
      // Favourte is not in the menu, so lets add it
      [self addFavouriteMenuItem:ramdisk atEnd:NO];
    }
  }
  // now run through all menu items and throw the ones away that have no favoureite anymore
  for( NSValue *itemId in [favouritesToMenuItemsMap allKeys] )
  {
    // Remove obsolte menu items
    if( ! [validItems containsObject:itemId] )
    {
      [favoritesMenu removeItem:[itemId nonretainedObjectValue]];
      [favouritesToMenuItemsMap removeObjectForKey:itemId];
    }
  }
  if( [favouriteManager.favourites count] == 0)
  {
    [self addNoFavouritesInfoAtEnd:FALSE];
  }
}


# pragma mark actions

- (void) quitApplication
{
  //Unmount ramdisk?
  [[NSApplication sharedApplication] terminate:nil];
}

- (void) showSettingsTab:(id)sender
{
  [((RMFAppDelegate*)[NSApp delegate]).settingsController showSettings:[sender representedObject]];
}

- (void)updateFavouriteState:(id)sender
{
  NSMenuItem* item = sender;
  NSValue *presetId = [favouritesToMenuItemsMap objectForKey:[NSValue valueWithNonretainedObject:item]];
  RMFRamdisk* itemPreset = [presetId nonretainedObjectValue];
  itemPreset.isMounted ? [self eject:itemPreset] : [self mount:itemPreset];
}

- (void) updateFavourite:(RMFRamdisk *)favourite
{
  NSValue *itemId = [[favouritesToMenuItemsMap allKeysForObject:[NSValue valueWithNonretainedObject:favourite]] lastObject];
  NSMenuItem *item = [itemId nonretainedObjectValue];
  [item setTitle:favourite.label];
}

# pragma mark mount/unmount

- (void) mount:(RMFRamdisk*) preset
{
  RMFCreateRamDiskOperation *mountOperation = [[RMFCreateRamDiskOperation alloc] initWithRamdisk:preset];
  [queue cancelAllOperations];
  [queue addOperation:mountOperation];
  [mountOperation release];
}

- (void)eject:(RMFRamdisk *)preset
{
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[preset.label volumePath]];
}

- (void) removeRamdisk
{
  [queue cancelAllOperations];
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
}

# pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if( [keyPath isEqualToString:RMFRamDiskLabel] )
  {
    if( [object isMemberOfClass:[RMFRamdisk class]] )
    {
      RMFRamdisk *ramDisk = (RMFRamdisk *)object;
      [self updateFavourite:ramDisk];    
      return;
    }
  }
  if( [keyPath isEqualToString:RMFFavouritesManagerFavourites] )
  {
    // clean up old key/value observing
    [self updateFavouritesMenu];
    return;
  }
}
@end

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
// updates the favourites menu for new additions
- (void) updateFavouritesMenu;
// updates the menu item represneting this favourite
- (void) updateFavourite:(RMFRamdisk *)favourite;
// callback to for a single favourite menu item
- (void) updateFavouriteState:(id)sender;

// Updates the menuitem to the changes in the ramdisk
// @param item MenuItem to update
// @param ramDisk Updated ramDisk
- (void) updateMenuItem:(NSMenuItem *)item ramDisk:(RMFRamdisk *)ramDisk;


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
                                                              options:( NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld )
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

# pragma mark Favourite Menu updates

- (BOOL)addFavouriteMenuItems:(NSArray *)favourites atEnd:(BOOL)atEnd
{
  BOOL didAddAllItems = YES;
  for( RMFRamdisk *disk in favourites )
  {
    didAddAllItems &= [self addFavouriteMenuItem:disk atEnd:atEnd];
  }
  return didAddAllItems;
}

- (void)addNoFavouritesInfoAtEnd:(BOOL)atEnd
{
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
  else
  {
    NSUInteger index = atEnd ? [favoritesMenu numberOfItems] : [favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                        initWithTitle:favorite.label
                        action:@selector(updateFavouriteState:)
                        keyEquivalent:@""];
    // Add ourselves as observer for label changes on the favourite
    // WARNING this might be a very bad idea to use non retained values
    [favorite addObserver:self forKeyPath:RMFRamDiskLabel options:0 context:[NSValue valueWithNonretainedObject:item]];
    [favorite addObserver:self forKeyPath:RMFRamDiskIsDirty options:0 context:[NSValue valueWithNonretainedObject:item]];
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

- (void)updateMenuItem:(NSMenuItem *)item ramDisk:(RMFRamdisk *)ramDisk
{
  if( [[favoritesMenu itemArray] containsObject:item] )
  {
    [item setTitle:ramDisk.label];
  }
}

- (void) removeFavouriteMenuItems:(NSArray *)favourites
{
  for(RMFRamdisk *disk in favourites)
  {
    [self removeFavouriteMenuItem:disk]; 
  }
}

- (BOOL) removeFavouriteMenuItem:(RMFRamdisk *)favourite
{
  NSValue *favouriteId = [NSValue valueWithNonretainedObject:favourite];
  NSValue *itemId = [[favouritesToMenuItemsMap allKeysForObject:favouriteId] lastObject];
  if(itemId != nil)
  {
    // remove all key-value-observer from the removed ramdisk
    [favourite removeObserver:self forKeyPath:RMFRamDiskLabel];
    [favourite removeObserver:self forKeyPath:RMFRamDiskIsDirty];
    NSMenuItem *item = [itemId nonretainedObjectValue];
    [favoritesMenu removeItem:item];
    
    return YES;
  }
  return NO;
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
  if( [keyPath isEqualToString:RMFRamDiskLabel] || [keyPath isEqualToString:RMFRamDiskIsDirty] )
  {
    if( [object isMemberOfClass:[RMFRamdisk class]] )
    {
      RMFRamdisk *ramDisk = (RMFRamdisk *)object;
      NSValue *itemId = (NSValue *)context;
      [self updateMenuItem:[itemId nonretainedObjectValue] ramDisk:ramDisk];
      return;
    }
  }
  if( [keyPath isEqualToString:RMFFavouritesManagerFavourites] )
  {
    NSUInteger changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
    switch (changeKind) {
      case NSKeyValueChangeInsertion: {
        NSArray *insertedItems = [change objectForKey:NSKeyValueChangeNewKey];
        [self addFavouriteMenuItems:insertedItems atEnd:YES];
      }
      case NSKeyValueChangeRemoval:
      default:{
        
        NSArray *removedItems = [change objectForKey:NSKeyValueChangeOldKey];
        [self removeFavouriteMenuItems:removedItems];
        break;
      }
    }
    
    
    [self updateFavouritesMenu];
    return;
  }
}
@end

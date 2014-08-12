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
#import "RMFVolumeObserver.h"
#import "NSString+RMFVolumeTools.h"
#import "NSString+RMFMenuTools.h"

NSString *const RMFMenuIconTemplateImage = @"MenuItemIconTemplate";
const NSUInteger RMFFavouritesMenuIndexOffset = 2;

@interface RMFMenuController ()
@property (retain) NSMenuItem *noFavouritesMenuItem;
@property (retain) NSMenuItem *hibernateWarningMenuItem;
@property (retain) NSMenu *menu;
@property (retain) NSMenu *favoritesMenu;
@property (retain) NSStatusItem *statusItem;
@property (retain) NSOperationQueue *queue;
@property (retain) NSMutableDictionary *menuItemsToFavouritesMap;

@end


@implementation RMFMenuController

#pragma mark object lifecycle
- (id)init {
  self = [super init];
  if (self) {
    _menuItemsToFavouritesMap = [[NSMutableDictionary alloc] init];
    [self _createMenu];
    [self _createStatusItem];
    RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
    [favouritesManager addObserver:self forKeyPath:kRMFFavouritesManagerKeyForFavourites options:( NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld ) context:nil];
    [favouritesManager addObserver:self forKeyPath:kRMFFavouritesManagerFavouritesKeyForDefaultRamdisk options:0 context:nil];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(_ramDiskChanged:) name:RMFVolumeObserverDidMountRamdiskNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(_ramDiskChanged:) name:RMFVolumeObserverDidUnmountRamdiskNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(_ramDiskChanged:) name:RMFVolumeObserverDidRenameRamdiskNotification object:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  
  // remove from observers
  [[RMFFavouritesManager sharedManager] removeObserver:self forKeyPath:kRMFFavouritesManagerKeyForFavourites];
  [[RMFFavouritesManager sharedManager] removeObserver:self forKeyPath:kRMFFavouritesManagerFavouritesKeyForDefaultRamdisk];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
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

- (void)_createFavouritesMenu {
  RMFFavouritesManager *manager = [RMFFavouritesManager sharedManager];
  _favoritesMenu = [[NSMenu alloc] initWithTitle:@"PresetsSubmenu"];
  
  for(RMFRamdisk *favorite in manager.favourites) {
    [self _addFavouriteMenuItem:favorite atEnd:YES];
  }
  
  if([manager.favourites count] == 0) {
    [self _addNoFavouritesWarningAtEnd:YES];
  }
  [_favoritesMenu addItem:[NSMenuItem separatorItem]];
}

- (void)_createMenu
{
  _menu = [[NSMenu alloc] initWithTitle:@"menu"];
  NSMenuItem *item;
  NSString *itemTitle;
  
  // About
  RMFAppDelegate *appDelegate = [NSApp delegate];
  NSString *appName = [appDelegate executabelName];
  NSString *aboutString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"MENU_ABOUT", @"The lolcalized Version of About"), appName];
  [self _addItemToMenu:_menu title:aboutString target:NSApp action:@selector(orderFrontStandardAboutPanel:) enabled:YES keyEquivalent:@""];
  
  // Preferences
  itemTitle = [NSString stringByAddingDots:NSLocalizedString(@"MENU_ITEM_PREFERENCES", @"Menu Item - Preferences")];
  item = [[self _addItemToMenu:_menu title:itemTitle target:self action:@selector(showSettingsTab:) enabled:YES keyEquivalent:@""] retain];
  [item setRepresentedObject:[RMFGeneralSettingsController identifier]];
  [item release];
  
  [_menu addItem:[NSMenuItem separatorItem]];
  
  // Create ramdisk
  itemTitle = NSLocalizedString(@"MENU_CREATE_RAMDISK", @"Create Ramdisk");
  [self _addItemToMenu:_menu title:itemTitle target:self action:@selector(_handleFavouriteClicked:) enabled:YES keyEquivalent:@""];
  
  // Destroy ramdisk
  itemTitle = NSLocalizedString(@"MENU_UNMOUNT_RAMDISK", @"Destroy Ramdisk");
  [self _addItemToMenu:_menu title:itemTitle target:self action:@selector(removeRamdisk) enabled:YES keyEquivalent:@""];
 
  // Favourites
  [self _createFavouritesMenu];
  
  itemTitle = [NSString stringByAddingDots:NSLocalizedString(@"MENU_MANAGE_FAVOURITES", @"Menu Manage Favourites")];
  item = [[self _addItemToMenu:_favoritesMenu title:itemTitle target:self action:@selector(showSettingsTab:) enabled:YES keyEquivalent:@""] retain];
  [item setRepresentedObject:[RMFFavouritesSettingsController identifier]];
  [item release];
  
  itemTitle = NSLocalizedString(@"COMMON_PLURAL_FAVOURITE", @"Favourites");
  item = [[self _addItemToMenu:_menu title:itemTitle target:self action:nil enabled:YES keyEquivalent:@""] retain];
  [item setSubmenu:self.favoritesMenu];
  [item release];
  
  // Separation
  [_menu addItem:[NSMenuItem separatorItem]];
  
  // Quit
  itemTitle = NSLocalizedString(@"COMMON_QUIT", @"Quit");
  item = [[self _addItemToMenu:_menu title:itemTitle target:self action:@selector(quitApplication) enabled:YES keyEquivalent:@""] retain];
  [item setKeyEquivalentModifierMask:NSCommandKeyMask];
  [item release];
  
  RMFSettingsController *settingsController = [RMFSettingsController sharedController];
  BOOL shouldDisplayWarning = ( [settingsController hibernateMode] != 0);
  [self setHibernateWarningVisible:shouldDisplayWarning];
}

- (NSMenuItem *)_addItemToMenu:(NSMenu *)aMenu title:(NSString *)aTitle target:(id)aTarget action:(SEL)anAction enabled:(BOOL)isEnabled keyEquivalent:(NSString *)key {
  NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aTitle action:anAction keyEquivalent:key];
  [item setEnabled:isEnabled];
  [item setTarget:aTarget];
  [aMenu addItem:item];
  return [item autorelease];
}

- (void)_createStatusItem {
  NSStatusBar *bar = [NSStatusBar systemStatusBar];
  self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
  NSImage *menuIconImage = [NSImage imageNamed:RMFMenuIconTemplateImage];
  [_statusItem setImage:menuIconImage];
  [_statusItem setEnabled:YES];
  [_statusItem setHighlightMode:YES];
  [_statusItem setMenu:self.menu];
}

# pragma mark Favourite Menu updates

- (BOOL)_addFavouriteMenuItems:(NSArray *)favourites atEnd:(BOOL)atEnd {
  BOOL didAddAllItems = YES;
  for( RMFRamdisk *disk in favourites ) {
    didAddAllItems &= [self _addFavouriteMenuItem:disk atEnd:atEnd];
  }
  return didAddAllItems;
}

- (void)_addNoFavouritesWarningAtEnd:(BOOL)atEnd {
  if(self.noFavouritesMenuItem == nil) {
    _noFavouritesMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]]
                             initWithTitle:NSLocalizedString(@"MENU_NO_FAVOURITES_DEFINED", @"Menu Item - No Favourites defined")
                             action:NULL
                             keyEquivalent:@""];
    
  }
  NSInteger index = atEnd ? [self.favoritesMenu numberOfItems] : [self.favoritesMenu numberOfItems] - RMFFavouritesMenuIndexOffset;
  NSArray *indexArray = @[@(index), @0];
  NSNumber *minimum = [indexArray valueForKeyPath:@"@min.intValue"];
  [self.favoritesMenu insertItem:self.noFavouritesMenuItem atIndex:[minimum integerValue]];
}

- (BOOL)_addFavouriteMenuItem:(RMFRamdisk *)favorite atEnd:(BOOL)atEnd {
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
                        action:@selector(_handleFavouriteClicked:)
                        keyEquivalent:@""];
    // Add ourselves as observer for label changes on the favourite
    [favorite addObserver:self forKeyPath:kRMFRamdiskKeyForLabel options:0 context:item];
    [favorite addObserver:self forKeyPath:kRMFRamdiskKeyForIsDefault options:0 context:item];
    if(favorite.isDefault) {
//      NSImage *isDefaultImage = [[NSBundle mainBundle] imageForResource:@"VolumeTemplate"];
//      [isDefaultImage setSize:NSMakeSize(16, 16)];
//      [item setImage:isDefaultImage];
    }
    [item setTarget:self];
    [_favoritesMenu insertItem:item atIndex:index];
    _menuItemsToFavouritesMap[[NSValue valueWithNonretainedObject:item]] = [NSValue valueWithNonretainedObject:favorite];
    [item release];
    
    return TRUE;
  }
}

- (void)_updateMenuItem:(NSMenuItem *)item ramDisk:(RMFRamdisk *)ramDisk {
  if( [[_favoritesMenu itemArray] containsObject:item] ) {
    [item setTitle:ramDisk.label];
    ramDisk.isMounted ? [item setState:NSOnState] : [item setState:NSOffState];
    //ramDisk.isDefault ? [item setImage:nil] : [item setImage:nil];
  }
}

- (void)_removeFavouriteMenuItems:(NSArray *)favourites {
  for(RMFRamdisk *disk in favourites) {
    [self _removeFavouriteMenuItem:disk];
  }
}

- (BOOL)_removeFavouriteMenuItem:(RMFRamdisk *)favourite {
  NSValue *favouriteId = [NSValue valueWithNonretainedObject:favourite];
  NSValue *itemId = [[_menuItemsToFavouritesMap allKeysForObject:favouriteId] lastObject];
  if(itemId != nil) {
    // remove all key-value-observer from the removed ramdisk
    [favourite removeObserver:self forKeyPath:kRMFRamdiskKeyForLabel];
    [favourite removeObserver:self forKeyPath:kRMFRamdiskKeyForIsDefault];
    NSMenuItem *item = [itemId nonretainedObjectValue];
    [_favoritesMenu removeItem:item];
    [_menuItemsToFavouritesMap removeObjectForKey:itemId];
    // Menu is empty
    if([_menuItemsToFavouritesMap count] == 0) {
      [self _addNoFavouritesWarningAtEnd:NO];
    }
    return YES;
  }
  return NO;
}

# pragma mark actions
- (void)quitApplication {
  //Unmount ramdisk?
  [[NSApplication sharedApplication] terminate:nil];
}

- (void)showSettingsTab:(id)sender {
  RMFSettingsController *settingsController = [RMFSettingsController sharedController];
  [settingsController showSettings:[sender representedObject]];
}

- (void)_handleFavouriteClicked:(id)sender {
  NSMenuItem* item = sender;
  NSValue *presetId = _menuItemsToFavouritesMap[[NSValue valueWithNonretainedObject:item]];
  RMFRamdisk* ramdisk = [presetId nonretainedObjectValue];
  [[RMFMountController sharedController] toggleMounted:ramdisk];
}

- (void)_updateFavourite:(RMFRamdisk *)favourite {
  NSValue *itemId = [[_menuItemsToFavouritesMap allKeysForObject:[NSValue valueWithNonretainedObject:favourite]] lastObject];
  if(itemId != nil) {
    NSMenuItem *item = [itemId nonretainedObjectValue];
    if(item == nil) {
      return; // no menu item found
    }
    [item setTitle:favourite.label];
    NSInteger state = favourite.isMounted ? NSOnState : NSOffState;
    [item setState:state];
  }
}

- (void)removeRamdisk {
  [_queue cancelAllOperations];
  // search if a ramdisk is active and detach it by calling
  // hdutil detach <Device>
}

- (void)setHibernateWarningVisible:(BOOL)isVisible {
  
  BOOL isWarningVisible = [[_menu itemArray] containsObject:_hibernateWarningMenuItem];
  
  if(isVisible != isWarningVisible) {
    if(isVisible) {
      if( _hibernateWarningMenuItem == nil ) {
        NSString *menuTitle = NSLocalizedString(@"MENU_WRONG_HIBERNATE_MODE", @"Menu Item - Current Hibernate mode causes ram disk to be unmounted after wake-up from sleep");
        _hibernateWarningMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:menuTitle action:NULL keyEquivalent:@""];
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
- (void)_ramDiskChanged:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  RMFRamdisk *ramdisk = userInfo[RMFVolumeObserverRamdiskKey];
  if(ramdisk == nil) {
    return; // no ramdisk sent
  }
  [self _updateFavourite:ramdisk];
}

# pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if( [keyPath isEqualToString:kRMFRamdiskKeyForLabel] || [keyPath isEqualToString:kRMFRamdiskKeyForIsDefault]) {
    if( [object isMemberOfClass:[RMFRamdisk class]] ) {
      RMFRamdisk *ramDisk = (RMFRamdisk *)object;
      NSMenuItem *item = context;
      [self _updateMenuItem:item ramDisk:ramDisk];
      return;
    }
  }
  if( [keyPath isEqualToString:kRMFFavouritesManagerKeyForFavourites] ) {
    NSUInteger changeKind = [change[NSKeyValueChangeKindKey] intValue];
    switch (changeKind) {
      case NSKeyValueChangeInsertion: {
        NSArray *insertedItems = change[NSKeyValueChangeNewKey];
        [self _addFavouriteMenuItems:insertedItems atEnd:NO];
        break;
      }
      case NSKeyValueChangeRemoval: {
        NSArray *removedItems = change[NSKeyValueChangeOldKey];
        [self _removeFavouriteMenuItems:removedItems];
        break;
      }
      default:
        break;
    }
  }
}
@end

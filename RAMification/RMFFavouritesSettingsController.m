//
//  RMFPresetSettingsContoller.m
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFFavouritesSettingsController.h"
#import "RMFScriptEditorController.h"
#import "RMFRamdisk.h"
#import "RMFAppDelegate.h"
#import "RMFFavouritesManager.h"
#import "RMFVolumeObserver.h"
#import "RMFMountController.h"
#import "RMFSizeFormatter.h"
#import "RMFArrayController.h"
#import "RMFSettingsController.h"

@interface RMFFavouritesSettingsController () {
  RMFArrayController *_favouritesController;
}
@property (strong) RMFFavouritesTableViewDelegate *tableDelegate;
@property (strong) RMFScriptEditorController *scriptController;

- (void)didLoadView;
- (void)didRenameFavourite:(NSNotification *)notification;
- (NSMenu *)backupModeMenu;
- (NSMenu *)labelMenu;
- (NSMenu *)actionContextMenu;
- (NSMenu *)actionPopupMenu;
- (NSImage *)labelImageWithColor:(NSColor *)color;

- (void)toggleMount:(id)sender;
- (void)makeDefaultRamdisk:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

- (RMFRamdisk *)_selectedRamdisk;

@end

@implementation RMFFavouritesSettingsController

+ (NSString *) identifier {
  return @"PresetSettings";
}

+ (NSString *) label {
  return NSLocalizedString(@"FAVOURITE_SETTINGS_LABEL", @"Label for the Preset Settings");
}

+ (NSToolbarItem *) toolbarItem {
  static NSToolbarItem *item;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    item = [[NSToolbarItem alloc] initWithItemIdentifier:[RMFFavouritesSettingsController identifier]];
    NSImage *toolbarImage = [[NSBundle mainBundle] imageForResource:@"favourite"];
    [item setImage:toolbarImage];
    [item setLabel:[RMFFavouritesSettingsController label]];
    [item setAction:@selector(showSettings:)];
  });
  return item;
}

#pragma mark init/dealloc
- (NSString *)nibName {
  return @"FavouritesPane";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRenameFavourite:) name:RMFVolumeObserverDidRenameRamdiskNotification object:nil];
  }
  return self;
}


#pragma mark view loading
// override to wait if a view was loaded
- (void)loadView {
  [super loadView];
  [self didLoadView];
}

- (void)didLoadView {
  
  // Array controller for the table view selection
  _favouritesController = [[RMFArrayController alloc] init];
  
  [_favouritesController bind:NSContentArrayBinding toObject:[RMFFavouritesManager sharedManager] withKeyPath:kRMFFavouritesManagerKeyForFavourites options:nil];
  [_favouriteColumn bind:NSValueBinding toObject:_favouritesController withKeyPath:NSContentArrayBinding options:nil];
  
  _tableDelegate = [[RMFFavouritesTableViewDelegate alloc] init];
  _favouritesTableView.delegate = self.tableDelegate;
  [_favouritesTableView setMenu:[self actionContextMenu]];
  
  [_backupPopUpButton setMenu:[self backupModeMenu]];
  [_labelPopupButton setMenu:[self labelMenu]];
  [_actionPopupButton setMenu:[self actionPopupMenu]];
  [_actionPopupButton selectItemAtIndex:0];
  
  [_sizeTextField setFormatter:[RMFSizeFormatter formatter]];
  
  // Setup bindings for the detail view
  NSString *selection = @"selection.%@";
  NSString *labelKeyPath = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(label))];
  NSString *automountKeyPath = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(isAutomount))];
  NSString *sizeKeyPath = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(size))];
  NSString *backupModeKeyPath = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(backupMode))];
  NSString *volumeIconKeyPath = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(volumeIcon))];
  NSString *finderLabelIndexKeyPath = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(finderLabelIndex))];
  NSString *isMountedKeyPath = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(isMounted))];
  NSString *isDefaultFavourite = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(isDefault))];
  NSString *hasMountScript = [NSString stringWithFormat:selection, NSStringFromSelector(@selector(hasMountScript))];
  
  NSDictionary *negateBooleanOption = @{ NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName };
  [_labelTextField bind:NSValueBinding toObject:_favouritesController withKeyPath:labelKeyPath options:nil];
  [_labelTextField bind:NSEnabledBinding toObject:_favouritesController withKeyPath:isMountedKeyPath options:negateBooleanOption];
  [_isAutoMountCheckButton bind:NSValueBinding toObject:_favouritesController withKeyPath:automountKeyPath options:nil];
  [_sizeTextField bind:NSValueBinding toObject:_favouritesController withKeyPath:sizeKeyPath options:nil];
  [_sizeTextField bind:NSEnabledBinding  toObject:_favouritesController withKeyPath:isMountedKeyPath options:negateBooleanOption];
  [_backupPopUpButton bind:NSSelectedIndexBinding toObject:_favouritesController withKeyPath:backupModeKeyPath options:nil];
  [_volumeIconImageView bind:NSValueBinding toObject:_favouritesController withKeyPath:volumeIconKeyPath options:nil];
  [_labelPopupButton bind:NSSelectedIndexBinding toObject:_favouritesController withKeyPath:finderLabelIndexKeyPath options:nil];
  [_removeRamdiskButton bind:NSEnabledBinding toObject:_favouritesController withKeyPath:isDefaultFavourite options:negateBooleanOption];
  [_useMountScriptCheckButton bind:NSValueBinding toObject:_favouritesController withKeyPath:hasMountScript options:nil];
  [_editScriptButton bind:NSEnabledBinding toObject:_favouritesController withKeyPath:hasMountScript options:nil];
  
  [_volumeIconImageView setImage:[[NSBundle mainBundle] imageForResource:@"Removable"]];
  [_sizeWarningImageView setImage:[NSImage imageNamed:NSImageNameCaution]];
}

#pragma mark Menus
- (NSMenu *)backupModeMenu {
  NSMenu *backupMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  for(NSUInteger eMode = 0; eMode < RMFBackupModeCount; eMode++) {
    switch (eMode) {
      case RMFNoBackup:
        [backupMenu addItemWithTitle:NSLocalizedString(@"RAMDISK_BACKUP_MODE_NO_BACKUP", @"Backup mode No Backup") action:NULL keyEquivalent:@""];
        break;
      case RMFBackupOnEject:
        [backupMenu addItemWithTitle:NSLocalizedString(@"RAMDISK_BACKUP_MODE_EJECT_ONLY", @"Backup mode Backup on Eject") action:NULL keyEquivalent:@""];
        break;
      case RMFBackupPeriodically:
        [backupMenu addItemWithTitle:NSLocalizedString(@"RAMDISK_BACKUP_MODE_PERIODICALLY", @"Backup mode Continously Backup") action:NULL keyEquivalent:@""];
        break;
    }
  }
  return backupMenu;
}

- (NSMenu *)labelMenu {
  NSMenu *labelMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSArray *labelColors = [workspace fileLabelColors];
  
  for(NSString *label in [workspace fileLabels]) {
    NSUInteger index = [[workspace fileLabels] indexOfObject:label];
    NSColor *labelColor = labelColors[index];
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:label action:NULL keyEquivalent:@""];
    
    if(index != 0) {
      [item setImage:[self labelImageWithColor:labelColor]];
    }
    else {
      [item setImage:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
    }
    
    [labelMenu addItem:item];
    
  }
  return labelMenu;
}

- (NSMenu *)actionPopupMenu {
  
  NSMenu *popupMenu = [self actionContextMenu];
  
  NSMenuItem *actionItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] init];
  [actionItem setImage:[NSImage imageNamed:NSImageNameActionTemplate]];
  [popupMenu insertItem:actionItem atIndex:0];
  
  return popupMenu;
}

- (NSMenu *)actionContextMenu {
  NSMenu *actionMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
  
  NSMenuItem *mountItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"COMMON_MOUNT", @"Mount Ramdisk")
                                                                               action:@selector(toggleMount:)
                                                                        keyEquivalent:@""];
  NSMenuItem *ejectItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"COMMON_EJECT", @"Eject")
                                                                               action:@selector(toggleMount:)
                                                                        keyEquivalent:@""];
  NSMenuItem *markAsDefaultItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"FAVOURITE_ACTION_MAKE_DEFAULT", @"Set Favourite as default Ramdisk")
                                                                                       action:@selector(makeDefaultRamdisk:)
                                                                                keyEquivalent:@""];
  // bind enable/disable to the mount state of a ramdisk
  NSDictionary *negateBindingOption = @{ NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName };
  NSString *selectionIsMountedKeyPath = [NSString stringWithFormat:@"selection.%@", NSStringFromSelector(@selector(isMounted))];
  NSString *selectionIsDefaultKeyPath = [NSString stringWithFormat:@"selection.%@", NSStringFromSelector(@selector(isDefault))];
  [mountItem bind:NSEnabledBinding toObject:_favouritesController withKeyPath:selectionIsMountedKeyPath options:negateBindingOption];
  [ejectItem bind:NSEnabledBinding toObject:_favouritesController withKeyPath:selectionIsMountedKeyPath options:nil];
  [markAsDefaultItem bind:NSEnabledBinding toObject:_favouritesController withKeyPath:selectionIsDefaultKeyPath options:negateBindingOption];
  
  [mountItem setTarget:self];
  [ejectItem setTarget:self];
  [markAsDefaultItem setTarget:self];
  
  [actionMenu addItem:mountItem];
  [actionMenu addItem:ejectItem];
  [actionMenu addItem:[NSMenuItem separatorItem]];
  [actionMenu addItem:markAsDefaultItem];
  
  
  return actionMenu;
}


# pragma mark actions
- (void)addPreset:(id)sender {
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  [favouriteManager addNewFavourite];
  //[_favouritesTableView reloadData];
}

- (void)deletePreset:(id)sender {
  // find the selected preset
  RMFFavouritesManager *favouriteManager = [RMFFavouritesManager sharedManager];
  NSInteger selectedRow = [_favouritesTableView selectedRow];
  if(-1 == selectedRow) {
    return;
  }
  RMFRamdisk *selectedFavourite = (favouriteManager.favourites)[selectedRow];
  [favouriteManager deleteFavourite:selectedFavourite];
  //[_favouritesTableView reloadData];
}

- (void)toggleMount:(id)sender {
  if(NO == [sender isMemberOfClass:[NSMenuItem class]]) {
    return; // wrong sender
  }
  RMFRamdisk *selectedRamdisk = [[_favouritesController selection] valueForKey:@"self"];
  if(nil != selectedRamdisk) {
    [[RMFMountController sharedController] toggleMounted:selectedRamdisk];
  }
}

- (void)makeDefaultRamdisk:(id)sender {
  if(NO == [sender isMemberOfClass:[NSMenuItem class]]) {
    return; // wrong sender
  }
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *selectedRamdisk = [[_favouritesController selection] valueForKey:@"self"];
  [favouritesManager setDefaultRamdisk:selectedRamdisk];
}

- (IBAction)selectVolumeIcon:(id)sender {
  
  if(self.iconSelectionWindow == nil) {
    NSArray *topLevelObjects;
    [[NSBundle mainBundle] loadNibNamed:@"VolumeIconSelection"owner:self topLevelObjects:&topLevelObjects];
  }  
  NSWindow *window = [RMFSettingsController sharedController].settingsWindow;
  [[NSApplication sharedApplication] beginSheet:self.iconSelectionWindow modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  NSLog(@"Return Code: %ld", returnCode);
  [sheet orderOut:sheet];
}

- (IBAction)cancelIconSelection:(id)sender {
  [[NSApplication sharedApplication] endSheet:self.iconSelectionWindow returnCode:NSRunAbortedResponse];
}

- (IBAction)finishedIconSelection:(id)sender {
  [[NSApplication sharedApplication] endSheet:self.iconSelectionWindow returnCode:NSRunContinuesResponse];
}

- (IBAction)showScriptEditor:(id)sender {
  if(!self.scriptController) {
    _scriptController = [[RMFScriptEditorController alloc] init];
  }
  [self.scriptController showScriptForRamdisk:[self _selectedRamdisk]];
}

- (IBAction)toggleUseMountScript:(id)sender {
  NSInteger state = [self.useMountScriptCheckButton state];
  [self.editScriptButton setEnabled:(state == NSOnState)];
  if(state == NSOffState) {
    [self _selectedRamdisk].mountScript = nil;
  }
}

#pragma mark Notifications
- (void)didRenameFavourite:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  RMFRamdisk *ramdisk = userInfo[RMFVolumeObserverRamdiskKey];
  NSArray *favourites = [[RMFFavouritesManager sharedManager] favourites];
  NSIndexSet *rowIndexSet = [NSIndexSet indexSetWithIndex:[favourites indexOfObject:ramdisk]];
  NSIndexSet *columIndexSet = [NSIndexSet indexSetWithIndex:0];
  [_favouritesTableView reloadDataForRowIndexes:rowIndexSet columnIndexes:columIndexSet];
}

- (NSImage *)labelImageWithColor:(NSColor *)color {
  return [NSImage imageWithSize:NSMakeSize(16, 16) flipped:NO drawingHandler:^BOOL(NSRect destRect){
    NSRect labelRect = NSMakeRect(0.5, 0.5, destRect.size.width - 4.0, destRect.size.width - 4.0);
    NSRect highlightRect = NSMakeRect(labelRect.origin.x + 1.0, labelRect.origin.y + 1.0, labelRect.size.height - 2.0, labelRect.size.width - 2.0);
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:labelRect xRadius:3.0 yRadius:3.0];
    NSBezierPath *hightlightPath = [NSBezierPath bezierPathWithRoundedRect:highlightRect xRadius:2.0 yRadius:2.0];
    
    [color setFill];
    [[color shadowWithLevel:0.5] setStroke];
    
    [path fill];
    [path stroke];
    [[color highlightWithLevel:0.5] setStroke];
    [hightlightPath stroke];
    
    return YES;

  }];
}

#pragma mark Helper

- (RMFRamdisk *)_selectedRamdisk {
  return [[RMFFavouritesManager sharedManager] favourites][[_favouritesController selectionIndex]];
}

@end

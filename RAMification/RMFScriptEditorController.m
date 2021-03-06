//
//  RMFScriptEditor.m
//  RAMification
//
//  Created by Michael Starke on 07.04.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "RMFScriptEditorController.h"
#import "RMFRamdisk.h"
#import "RMFRamdiskScript.h"

@interface RMFScriptEditorController ()

@property (unsafe_unretained) IBOutlet NSTextView *scriptTextView;
@property (weak) IBOutlet NSPopUpButton *languagePopupButton;
@property (weak) RMFRamdisk *ramdisk;

@end

@implementation RMFScriptEditorController

- (NSString *)windowNibName {
  return @"ScriptEditor";
}

- (void)windowDidLoad {
  [super windowDidLoad];
  
  /*
   Setup language selection
   */
  NSMenu *languageMenu = [[NSMenu alloc] init];
  NSDictionary *languages = [RMFRamdiskScript availableLanguages];
  for(NSNumber *languageNumber in languages.allKeys) {
    RMFScriptLanguage language = (RMFScriptLanguage)languageNumber.integerValue;
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = languages[languageNumber];
    item.tag = language;
    [languageMenu addItem:item];
  }
  (self.languagePopupButton).menu = languageMenu;

  /*
   Setup textview
   */
  NSFont *font = [[NSFontManager sharedFontManager] fontWithFamily:@"Menlo" traits:(NSUnboldFontMask|NSUnitalicFontMask) weight:0 size:12];
  (self.scriptTextView).font = font;
  [self.scriptTextView setRichText:NO];
  [self.scriptTextView setUsesFontPanel:NO];
}

- (void)showScriptForRamdisk:(RMFRamdisk *)ramdisk {
  self.ramdisk = ramdisk;
  if(!ramdisk) {
    return; // no Ramdisk, so nothing to do!
  }
  if(ramdisk.hasMountScript) {
    RMFRamdiskScript *script = ramdisk.mountScript;
    [self.languagePopupButton selectItemWithTag:script.language];
    (self.scriptTextView).string = script.script;
  }
  else {
    [self.languagePopupButton selectItemAtIndex:0];
    (self.scriptTextView).string = @"";
  }
  [self.window makeKeyAndOrderFront:self];
}


- (IBAction)save:(id)sender {
  if(self.ramdisk) {
    RMFScriptLanguage language = (RMFScriptLanguage)(self.languagePopupButton).selectedTag;
    NSString *scriptContent = (self.scriptTextView).string;
    
    if(!self.ramdisk.mountScript) {
      RMFRamdiskScript *script = [[RMFRamdiskScript alloc] initWithScript:scriptContent language:language];
      self.ramdisk.mountScript = script;
    }
    else {
      self.ramdisk.mountScript.language = language;
      self.ramdisk.mountScript.script = scriptContent;
    }
    
  }
  [self.window close];
}

- (IBAction)cancel:(id)sender {
  [self.window close];
}
@end

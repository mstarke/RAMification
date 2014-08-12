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

@property (assign) IBOutlet NSTextView *scriptTextView;
@property (assign) IBOutlet NSPopUpButton *languagePopupButton;
@property (assign) RMFRamdisk *ramdisk;

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
  for(NSNumber *languageNumber in [languages allKeys]) {
    RMFScriptLanguage language = (RMFScriptLanguage)[languageNumber integerValue];
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [item setTitle:languages[languageNumber]];
    [item setTag:language];
    [languageMenu addItem:item];
    [item release];
  }
  [self.languagePopupButton setMenu:languageMenu];
  [languageMenu release];

  /*
   Setup textview
   */
  NSFont *font = [[NSFontManager sharedFontManager] fontWithFamily:@"Menlo" traits:(NSUnboldFontMask|NSUnitalicFontMask) weight:0 size:12];
  [self.scriptTextView setFont:font];
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
    [self.scriptTextView setString:script.script];
  }
  else {
    [self.languagePopupButton selectItemAtIndex:0];
    [self.scriptTextView setString:@""];
  }
  [[self window] makeKeyAndOrderFront:self];
}


- (IBAction)save:(id)sender {
  if(self.ramdisk) {
    RMFScriptLanguage language = (RMFScriptLanguage)[self.languagePopupButton selectedTag];
    NSString *scriptContent = [self.scriptTextView string];
    
    if(!self.ramdisk.mountScript) {
      RMFRamdiskScript *script = [[RMFRamdiskScript alloc] initWithScript:scriptContent language:language];
      self.ramdisk.mountScript = script;
      [script release];
    }
    else {
      self.ramdisk.mountScript.language = language;
      self.ramdisk.mountScript.script = scriptContent;
    }
    
  }
  [[self window] close];
}

- (IBAction)cancel:(id)sender {
  [[self window] close];
}
@end

//
//  RMFScriptEditor.h
//  RAMification
//
//  Created by Michael Starke on 07.04.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class RMFRamdisk;

@interface RMFScriptEditorController : NSWindowController

- (void)showScriptForRamdisk:(RMFRamdisk *)ramdisk;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end

//
//  RMFDefaultSettingsContoller.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsControllerProtocol.h"

@interface RMFGeneralSettingsController : NSViewController <RMFSettingsControllerProtocol>

@property (assign) IBOutlet NSTextField *labelInput;
@property (assign) IBOutlet NSTextField *sizeInput;
@property (assign) IBOutlet NSStepper *sizeStepper;
@property (assign) IBOutlet NSButton *startAtLoginCheckButton;
@property (assign) IBOutlet NSTextField *sizeInfo;
@property (assign) IBOutlet NSTextField *hibernateWarning;
@property (assign) IBOutlet NSButton *isBufferDisabled;
@property (assign) IBOutlet NSPopUpButton *backupIntervalPopUp;

@end

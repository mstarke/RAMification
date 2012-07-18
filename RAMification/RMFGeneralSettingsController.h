//
//  RMFDefaultSettingsContoller.h
//  RAMification
//
//  Created by Michael Starke on 30.11.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMFSettingsControllerProtocol.h"

extern const NSUInteger MinimumBackupInterval;
extern const NSUInteger MaxiumumBackupInterval;
extern const NSUInteger BackupdIntervalStepSize;
extern const NSUInteger MinumumRamdiskSize;
extern const NSUInteger MaxiumumRamdiskSize;
extern const NSUInteger RamdiskSizeStepSize;

@interface RMFGeneralSettingsController : NSViewController <RMFSettingsControllerProtocol>

@property (assign) IBOutlet NSTextField *labelInput;
@property (assign) IBOutlet NSTextField *sizeInput;
@property (assign) IBOutlet NSTextField *backupIntervalInput;
@property (assign) IBOutlet NSStepper *sizeStepper;
@property (assign) IBOutlet NSStepper *backupIntervalStepper;
@property (assign) IBOutlet NSButton *startAtLoginCheckButton;
@property (assign) IBOutlet NSTextField *sizeInfo;
@property (assign) IBOutlet NSTextField *hibernateWarning;

@end

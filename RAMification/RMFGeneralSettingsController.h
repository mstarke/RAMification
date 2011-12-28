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
{
  IBOutlet NSPopUpButton *backupPathSelection;
  IBOutlet NSTextField *backupInterval;
  IBOutlet NSTextField *label;
  IBOutlet NSTextField *size;
  IBOutlet NSStepper *sizeStepper;
  IBOutlet NSStepper *backupIntervalStepper;
}

- (IBAction)setBackupInterval:(id)sender;
- (void)didLoadView;

@end

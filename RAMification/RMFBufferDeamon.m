//
//  RMFBufferDeamon.m
//  RAMification
//
//  Created by michael starke on 06.09.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFBufferDeamon.h"

#import "RMFFavouritesManager.h"
#import "RMFVolumeObserver.h"
#import "RMFRamdisk.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"

@interface RMFBufferDeamon ()

@property (assign) BOOL isObservingNotifications;
@property (nonatomic, setter = setBufferEnabled:) BOOL bufferEnabled;

@end

@implementation RMFBufferDeamon

- (instancetype)init {
  self = [super init];
  if (self) {
    _isObservingNotifications = NO;
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSString *keyPath = [NSString stringWithFormat:@"values.%@", RMFSettingsKeyDisableUnifiedBuffer];
    [self bind:@"bufferEnabled" toObject:defaultsController withKeyPath:keyPath options:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

-(void)dealloc {
  if(YES == _isObservingNotifications ) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
}

- (void)setBufferEnabled:(BOOL)bufferEnabled {
  NSLog(@"%@: Called setBufferEnabled", self);
  if(bufferEnabled != _bufferEnabled) {
    _bufferEnabled = bufferEnabled;
    [self enable:bufferEnabled];
  }
}

- (void)enable:(BOOL)enable {
  
  NSArray *mountedRamdisks = [[RMFFavouritesManager sharedManager] mountedFavourites];
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  
  if(enable) {
    for(RMFRamdisk *ramdisk in mountedRamdisks) {
      [self setShouldBuffer:enable forRamdisk:ramdisk];
    }
    // Register for notifications
    if( NO == _isObservingNotifications) {
      [defaultCenter addObserver:self selector:@selector(didCreateFile:) name:RMFVolumeObserverDidCreateFileOnRamdiskNotification object:nil];
      [defaultCenter addObserver:self selector:@selector(didMountRamdisk:) name:RMFVolumeObserverDidMountRamdiskNotification object:nil];
      self.isObservingNotifications = YES;
    }
  }
  else {
    // Unregister the notifications
    if( YES == _isObservingNotifications) {
      [defaultCenter removeObserver:self];
      self.isObservingNotifications = NO;
    }
    
    for(RMFRamdisk *ramdisk in mountedRamdisks) {
      // enable buffer for all files on ramdisk ... potentially dangerous?
    }
  }
}

# pragma mark Notifictaions
- (void)didCreateFile:(NSNotification *)notification {
  // TODO!
}

- (void)didMountRamdisk:(NSNotification *)notification {
  if(_bufferEnabled) {
    return; // nothing to du;
  }
  NSDictionary *userInfo = notification.userInfo;
  RMFRamdisk *ramdisk = userInfo[RMFVolumeObserverRamdiskKey];
  if(nil == ramdisk ) {
    return; // no ramdisk;
  }
  [self setShouldBuffer:_bufferEnabled forRamdisk:ramdisk];
}

#pragma mark Buffer handling
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk {
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *volumePath = (ramdisk.volumeURL).path;
  NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:volumePath];
  NSString *file;
  while( file = [dirEnumerator nextObject] ) {
    [self shouldBuffer:(!shouldBuffer) file:file];
  }
}

- (void)shouldBuffer:(BOOL)shouldBuffer file:(NSString *)file {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(NO == [fileManager fileExistsAtPath:file]) {
    return; // No valid file found
  }
  NSString *actionString = (shouldBuffer ? @"enable" : @"disable");
  const int fileDesciptor= open(file.UTF8String, O_RDONLY);
  if(fileDesciptor >= 0) {
    if(shouldBuffer){
      //fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 0); // Turn UBC on
      
    }
    else {
      //fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 1); // Turn UBC off
    }
    close(fileDesciptor);
    NSLog(@"%@: Did %@ cache for file %@ !", self, actionString, file );
  }
  else {
    NSLog(@"%@: Could not %@ cache for file %@ becaus the File could not be found!", self, actionString, file );
  }
}
@end

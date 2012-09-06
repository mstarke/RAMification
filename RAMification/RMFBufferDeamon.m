//
//  RMFBufferDeamon.m
//  RAMification
//
//  Created by michael starke on 06.09.12.
//  Copyright (c) 2012 HicknHack Software GmbH. All rights reserved.
//

#import "RMFBufferDeamon.h"

#import "RMFFavoriteManager.h"
#import "RMFRamdisk.h"
#import "RMFSettingsKeys.h"
#import "NSString+RMFVolumeTools.h"

@interface RMFBufferDeamon (PrivateMethods)
- (void)update;
- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk;
- (void)watchForChanges:(BOOL)shouldWath onRamdisk:(RMFRamdisk *)ramdisk;
- (void)disableCache:(BOOL)disable forFile:(NSString*)file;
@end


@implementation RMFBufferDeamon

- (id)init {
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSUserDefaultsDidChangeNotification object:nil];
  }
  return self;
}

- (void)update {
  BOOL shouldBuffer = [[NSUserDefaults standardUserDefaults] boolForKey:RMFSettingsKeyDisableUnifiedBuffer];
  
  RMFFavoriteManager *favoriteManager = [RMFFavoriteManager manager];
  NSArray *mountedFavourites = [favoriteManager mountedFavourites];
  for(RMFRamdisk *ramdisk in mountedFavourites) {
    [self setShouldBuffer:shouldBuffer forRamdisk:ramdisk];
  }
}

- (void)setShouldBuffer:(BOOL)shouldBuffer forRamdisk:(RMFRamdisk *)ramdisk {
  [self watchForChanges:shouldBuffer onRamdisk:ramdisk];
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *volumePath = [ramdisk.label volumePath];
  NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:volumePath];
  NSString *file;
  while( file = [dirEnumerator nextObject] ) {
    [self disableCache:(!shouldBuffer) forFile:file];
  }
}

- (void)watchForChanges:(BOOL)shouldWath onRamdisk:(RMFRamdisk *)ramdisk {
  // register for file changes on ramdisk
}

- (void)disableCache:(BOOL)disable forFile:(NSString *)file {
  char filename[1024];
  [file getCString:filename maxLength:1024 encoding:NSUTF8StringEncoding];
  
  int fileDesciptor= open(filename, O_RDONLY);
  if (fileDesciptor == 0) {
    if (disable)
      fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 1); // Turn UBC off
  }
  else {
    fcntl(fileDesciptor, F_GLOBAL_NOCACHE, 0); // Turn UBC on
  }
  close(fileDesciptor);
}
@end

//
//  RMFMountWatcher.m
//  RAMification
//
//  Created by Michael Starke on 14.12.11.
//  Copyright (c) 2011 HicknHack Software GmbH. All rights reserved.
//

#import "RMFVolumeObserver.h"

#import "RMFAppDelegate.h"
#import "RMFFavouritesManager.h"
#import "RMFRamdisk.h"
#import "RMFChangedMountedFavouritesController.h"

#import <DiskArbitration/DiskArbitration.h>

/*
 Notifications
 */
NSString *const RMFVolumeObserverDidMountRamdiskNotification = @"RMFDidMountRamdiskNotification";
NSString *const RMFVolumeObserverDidUnmountRamdiskNotification = @"RMFDidUnmountRamdiskNotification";
NSString *const RMFVolumeObserverDidRenameRamdiskNotification = @"RMFDidRenameRamdiskNotification";
NSString *const RMFVolumeObserverDidCreateFileOnRamdiskNotification = @"RMFDidCreateFileOnRamdiskNotification";
NSString *const RMFVolumeObserverDidChangeFileAttributesNotification = @"RMFDidChangeFileAttributesNotification";
/*
 Keys to access the userInfo dictionary attached to notifications
 */
NSString *const RMFVolumeObserverRamdiskKey = @"RMFVolumeObserverRamdiskKey";
NSString *const RMFVolumeObserverLabelBeforeRenameKey = @"RMFVolumeObserverLabelBeforeRenameKey";
NSString *const RMFVolumeObserverVolumeURLBeforeRenameKey = @"RMFVolumeObserverVolumeURLBeforeRenameKey";
NSString *const RMFVolumeObserverWasAlreadyMountedOnStartupKey =@"RMFVolumeObserverWasAlreadyMountedOnStartupKey";
NSString *const RMFVolumeObserverPathOfCreatedFileOnRamdiskKey = @"RMFVolumeObserverPathOfCreatedFileOnRamdiskKey";

@interface RMFVolumeObserver () {
  FSEventStreamRef _eventStream;
}

@property (retain) RMFChangedMountedFavouritesController *changedFavouritesController;
@property (retain) NSMutableDictionary *watchedRamdisks;
@property (assign) FSEventStreamEventId lastEventId;

- (void)_didMountVolume:(NSNotification *)notification;
- (void)_didUnmountVolume:(NSNotification *)notification;
- (void)_didRenameVolume:(NSNotification *)notification;
- (void)_setupMountedRamdisk:(RMFRamdisk *)ramdisk volumeURL:(NSURL *)volumeURL wasMountedAtStartup:(BOOL)wasMounted;
- (void)_showChangedRamdisksWindow:(NSArray *)ramdisks;
- (void)_eventsAtPath:(NSArray *)paths flags:(const FSEventStreamEventFlags[])flags;
- (void)_watchRamdisk:(RMFRamdisk *)ramdisk;
- (void)_changeWatchedRamdiskURL:(RMFRamdisk *)ramdisk oldURL:(NSURL *)oldURL newURL:(NSURL *)newURL;
- (void)_unwatchRamdisk:(RMFRamdisk *)ramdisk;
- (void)_unwatchAllRamdisks;
- (void)_updateFilesystemCallback;

@end

/*
 FSEvent callback bridign to RMFFileEventsWatcher
 */
static void fileSystemEventCallback(ConstFSEventStreamRef streamRef
                                    , void *userData
                                    , size_t numEvents
                                    , void *eventPaths
                                    , const FSEventStreamEventFlags eventFlags[]
                                    , const FSEventStreamEventId eventIds[]) {
  RMFVolumeObserver *volumeObserver = (RMFVolumeObserver *)userData;
  [volumeObserver _eventsAtPath:(NSArray *)eventPaths flags:eventFlags];
}

@implementation RMFVolumeObserver

+ (NSString *)bsdDeviceForVolumeAtURL:(NSURL *)volumeURL {
  // Create DA session and schedule it with run loop
  DASessionRef session = DASessionCreate(kCFAllocatorDefault);
  DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  // Get the disk for the path of the renamed volume
  DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, (CFURLRef)volumeURL);
  NSString *bsdDevice = @(DADiskGetBSDName(disk));
  // Unschedule our session and clean up
  DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  CFRelease(disk);
  CFRelease(session);
  
  return bsdDevice;
}

- (id)init {
  self = [super init];
  if (self) {
    
    _eventStream = NULL;
    _watchedRamdisks = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSNotificationCenter *center = [workspace notificationCenter];
    // Register ourselves for mount/unmount events to easly update favourite mount status
    [center addObserver:self selector:@selector(_didMountVolume:) name:NSWorkspaceDidMountNotification object:nil];
    [center addObserver:self selector:@selector(_didUnmountVolume:) name:NSWorkspaceDidUnmountNotification object:nil];
    [center addObserver:self selector:@selector(_didRenameVolume:) name:NSWorkspaceDidRenameVolumeNotification object:nil];
    NSLog(@"Created %@", [self class]);
  }
  return self;
}

- (void)dealloc {
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  NSNotificationCenter *center = [workspace notificationCenter];
  [center removeObserver:self];
  
  [super dealloc];
}

- (void)searchForMountedFavourites {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *mountedVolumeUrls = [fileManager mountedVolumeURLsIncludingResourceValuesForKeys:@[ NSURLVolumeNameKey, NSURLVolumeTotalCapacityKey, NSURLVolumeIsRemovableKey ] options:0];
  NSMutableArray *ramdiskWithChangedLabel = [NSMutableArray arrayWithCapacity:[mountedVolumeUrls count]];
  for( NSURL *volumeURL in mountedVolumeUrls) {
    BOOL hasValue = YES;
    NSString *name;
    NSNumber *capacity;
    NSNumber *isRemovable;
    hasValue &= [volumeURL getResourceValue:&name forKey:NSURLVolumeNameKey error:nil];
    hasValue &= [volumeURL getResourceValue:&capacity forKey:NSURLVolumeTotalCapacityKey error:nil];
    hasValue &= [volumeURL getResourceValue:&isRemovable forKey:NSURLVolumeIsRemovableKey error:nil];
    
    if(!hasValue) {
      continue; // No information. Skipp
    }
    
    if( [RMFRamdisk volumeIsRamdiskAtURL:volumeURL] ) {
      NSLog(@"Found already possible mounted favourite: %@. Trying to match up!", name);
      // find uuid by reading file
      BOOL foundUUID = NO;
      NSString *uuid = [RMFRamdisk uuidOfRamdiskAtAURL:volumeURL success:&foundUUID];
      
      if(foundUUID) {
        RMFRamdisk *ramdisk = [[RMFFavouritesManager sharedManager] findFavouriteByUUID:uuid];
        if(nil != ramdisk) {
          NSString *mountedLabel = [volumeURL lastPathComponent];
          if(NO == [ramdisk.label isEqualToString:mountedLabel]) {
            [ramdiskWithChangedLabel addObject:ramdisk];
          }
          [self _setupMountedRamdisk:ramdisk volumeURL:volumeURL wasMountedAtStartup:YES];
        }
      }
    }
  }
  if([ramdiskWithChangedLabel count] != 0) {
    [self _showChangedRamdisksWindow:ramdiskWithChangedLabel];
  }
}
#pragma marks volume notifictaions
- (void)_didMountVolume:(NSNotification *)notification {
  NSString *volumeName = [notification userInfo][NSWorkspaceVolumeLocalizedNameKey];
  NSURL *volumeURL = [notification userInfo][NSWorkspaceVolumeURLKey];
  NSString *volumePath = [volumeURL path];
  
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  NSString *bsdDevice = [RMFVolumeObserver bsdDeviceForVolumeAtURL:volumeURL];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteWithBsdDevice:bsdDevice];
  
  NSLog(@"%@: Device %@ got mounted at Path %@", self, bsdDevice, volumePath);
  if(ramdisk == nil || NO == [ramdisk.label isEqualToString:volumeName]) {
    NSLog(@"%@: No Ramdisk, ignoring!", self);
    return; // No known favourite was mounted, ignore
  }
  [self _setupMountedRamdisk:ramdisk volumeURL:volumeURL wasMountedAtStartup:NO];
}

- (void)_didUnmountVolume:(NSNotification *)notification {
  NSURL *deviceUrl = [notification userInfo][NSWorkspaceVolumeURLKey];
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  RMFRamdisk *ramdisk = [favouritesManager findFavouriteWithVolumeURL:deviceUrl];
  NSLog(@"%@: Device %@ unmounted", self, deviceUrl);
  if( ramdisk == nil ) {
    NSLog(@"%@: No Ramdisk, ignoring", self);
    return; // No known favourite was unmounted, ignore
  }
  
  [self _unwatchRamdisk:ramdisk];
  if(NO == ramdisk.isMounted) {
    NSLog(@"%@: Ramdisk %@ wasn't mounted", self, ramdisk.label);
    return; // RAM disk was not mounted
  }
  
  ramdisk.bsdDevice = nil;
  ramdisk.isMounted = NO;
  
  NSDictionary *userInfo = @{ RMFVolumeObserverRamdiskKey : ramdisk };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFVolumeObserverDidUnmountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@: %@ was unmounted!", self, ramdisk);
}

- (void)_didRenameVolume:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  NSURL *newURL = userInfo[NSWorkspaceVolumeURLKey];
  NSString *newName =userInfo[NSWorkspaceVolumeLocalizedNameKey];
  NSURL *oldURL = userInfo[NSWorkspaceVolumeOldURLKey];
  NSString *oldName = userInfo[NSWorkspaceVolumeOldLocalizedNameKey];
  
  NSLog(@"%@: Volume %@ got renamed to %@", self, oldName, newName);
  RMFFavouritesManager *favouritesManager = [RMFFavouritesManager sharedManager];
  
  BOOL didReadUUID = NO;
  NSString *uuid = [RMFRamdisk uuidOfRamdiskAtAURL:newURL success:&didReadUUID];
  if( didReadUUID ) {
    RMFRamdisk *renamedDisk = [favouritesManager findFavouriteByUUID:uuid];
    if(renamedDisk != nil) {
      NSDictionary *userInfo = @{ RMFVolumeObserverRamdiskKey : renamedDisk, RMFVolumeObserverLabelBeforeRenameKey : oldName, RMFVolumeObserverVolumeURLBeforeRenameKey: oldURL };
      renamedDisk.label = newName;
      renamedDisk.volumeURL = newURL;
      [self _changeWatchedRamdiskURL:renamedDisk oldURL:oldURL newURL:newURL];
      [[NSNotificationCenter defaultCenter] postNotificationName:RMFVolumeObserverDidRenameRamdiskNotification object:self userInfo:userInfo];
    }
  }
}

#pragma marks volume handling
- (void)_setupMountedRamdisk:(RMFRamdisk *)ramdisk volumeURL:(NSURL *)volumeURL wasMountedAtStartup:(BOOL)wasMounted {
  ramdisk.volumeURL = volumeURL;
  ramdisk.isMounted = YES;
  [ramdisk updateFinderLabel];
  [ramdisk prepareContent];
  
  // Post usernotification to userNotificationCenter only if we did mount the ramdisk ourselfs
  if(NO == wasMounted) {
    NSUserNotificationCenter *notificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *userNotification = [[[NSUserNotification alloc] init] autorelease];
    userNotification.title = NSLocalizedString(@"NOTIFICATION_RAMDISK_CREATED", @"Ramdisk was created successfully");
    userNotification.subtitle = ramdisk.label;
    userNotification.deliveryDate = [NSDate date];
    
    [notificationCenter scheduleNotification:userNotification];
  }
  
  [self _watchRamdisk:ramdisk];
  
  NSDictionary *userInfo = @{ RMFVolumeObserverRamdiskKey : ramdisk, RMFVolumeObserverWasAlreadyMountedOnStartupKey : @(wasMounted) };
  [[NSNotificationCenter defaultCenter] postNotificationName:RMFVolumeObserverDidMountRamdiskNotification object:self userInfo:userInfo];
  NSLog(@"%@: %@ was mounted!", self, ramdisk);
}

- (void)_showChangedRamdisksWindow:(NSArray *)ramdisks {
  // show dialog with changed ramdisks
  _changedFavouritesController =  [[RMFChangedMountedFavouritesController alloc] init];
  [_changedFavouritesController setChangedFavourites:ramdisks];
  [_changedFavouritesController showWindow:[_changedFavouritesController window]];
}

# pragma mark FSEvent processing
- (void)_eventsAtPath:(NSArray *)paths flags:(const FSEventStreamEventFlags [])flags {
  /*
   We receive events for paths that we watch
   
   Handle root changes (= renaming)
   Handle unmountings (> remove from watchlist)
   Update buffer on new files
   
   Ignore Mount, Removal (nothing to do there)
   */
  for(NSString *path in paths) {
    // Check what ramdisk this event corresponds to
    NSUInteger index = [paths indexOfObject:path];
    FSEventStreamEventFlags flag = flags[index];
    NSLog(@"FS Event for %@ flag: %d", path, flag);
    
    RMFRamdisk *affectedRamdisk = nil;
    BOOL didMatchPath = NO;
    for(NSURL *url in _watchedRamdisks ) {
      if([path hasPrefix:[url path]]) {
        affectedRamdisk = _watchedRamdisks[url];
        didMatchPath = YES;
        continue;
      }
    }
    if(NO == didMatchPath) {
      return; // we did not find a path
    }
    if(flag & kFSEventStreamEventFlagItemCreated) {
      NSLog(@"Created");
      NSDictionary *userInfo = @{ RMFVolumeObserverRamdiskKey: affectedRamdisk, RMFVolumeObserverPathOfCreatedFileOnRamdiskKey: path };
      [[NSNotificationCenter defaultCenter] postNotificationName:RMFVolumeObserverDidCreateFileOnRamdiskNotification object:self userInfo:userInfo];
    }
    /*
     Modification is only necessary if it happens on the volume,
     everything else we do not care about
     */
    const BOOL didModifyFileVolume = (flag & kFSEventStreamEventFlagItemXattrMod) && [[affectedRamdisk.volumeURL path] isEqualToString:path];
    if(didModifyFileVolume) {
      NSError *error = nil;
      NSDictionary *resourceValues = [affectedRamdisk.volumeURL resourceValuesForKeys:@[NSURLLabelNumberKey] error:&error];
      if(nil == error) {
        NSUInteger currentLabelIndex = [resourceValues[NSURLLabelNumberKey] integerValue];
        NSLog(@"%@: Testing for label change on Ramdisk %@", [self class], affectedRamdisk);
        if(currentLabelIndex != affectedRamdisk.finderLabelIndex) {
          NSLog(@"%@: Label missmatch detected. Updating!", [self class]);
          affectedRamdisk.finderLabelIndex = currentLabelIndex;
        }
      }
      else {
        NSLog(@"%@", [error localizedDescription]);
      }
    }
  }
}

- (void)_updateFilesystemCallback {
  // Unshedule the Eventstream callback but remmber the last eventID
  NSLog(@"%@: Updating FSEvents callback", [self class]);
  if( _eventStream != NULL ) {
    NSLog(@"%@: Found old callback. Removing.", [self class]);
    FSEventStreamStop(_eventStream);
    FSEventStreamInvalidate(_eventStream);
    self.lastEventId = FSEventStreamGetLatestEventId(_eventStream);
    FSEventStreamRelease(_eventStream);
    _eventStream = NULL;
  }
  else {
    self.lastEventId = FSEventsGetCurrentEventId();
  }
  
  // Nothing to watch
  if([_watchedRamdisks count] == 0) {
    NSLog(@"%@: No RAM disk mounted. Nothing to regiser for", [self class]);
    return; // nothing to watch
  }
  
  // We got some paths to watch so generate a new callback
  FSEventStreamContext context = {0, (void *)self, NULL, NULL, NULL};
  const NSTimeInterval latency = 1.0;
  // Watch for File events (Create, Modify, Remove,) and use CF Storage types on callback
  const FSEventStreamCreateFlags flags = (kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes);
  
  NSMutableSet *volumePaths = [[[NSMutableSet alloc] initWithCapacity:[_watchedRamdisks count]] autorelease];
  for(RMFRamdisk *ramdisk in [_watchedRamdisks allValues]) {
    [volumePaths addObject:[ramdisk.volumeURL path]];
  }
  _eventStream = FSEventStreamCreate(NULL,
                                     &fileSystemEventCallback,
                                     &context,
                                     (CFArrayRef)[volumePaths allObjects],
                                     _lastEventId,
                                     (CFTimeInterval)latency,
                                     flags);
  
  FSEventStreamScheduleWithRunLoop(_eventStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
  FSEventStreamStart(_eventStream);
  NSLog(@"%@: Registerd callbacks for following paths: %@", [self class], [volumePaths allObjects]);
}

- (void)_watchRamdisk:(RMFRamdisk *)ramdisk {
  if(nil == ramdisk) {
    return; // no ramdisk;
  }
  
  if([[_watchedRamdisks allValues] containsObject:ramdisk]) {
    return; // already watching this one
  }
  
  NSError *error = nil;
  NSDictionary *resourceValues = [ramdisk.volumeURL resourceValuesForKeys:@[NSURLIsVolumeKey, ] error:&error];
  
  if(error != nil) {
    NSLog(@"%@: An Error occured while trying to wath URL %@ for changes. %@", [self class], ramdisk.volumeURL, [error localizedDescription]);
    return; // error while reading
  }
  
  BOOL isVolume = [resourceValues[NSURLIsVolumeKey] boolValue];
  if(NO == isVolume) {
    NSLog(@"%@: URL %@ does not point to a Volume. Ignoring", [self class], ramdisk.volumeURL);
    return; // URL does not point to a Volume
  }
  _watchedRamdisks[ramdisk.volumeURL] = ramdisk;
  [self _updateFilesystemCallback];
}

- (void)_unwatchRamdisk:(RMFRamdisk *)ramdisk {
  if(nil == ramdisk) {
    return; // no ramdisk
  }
  if(NO == [[_watchedRamdisks allValues] containsObject:ramdisk]) {
    return; // not watched
  }
  [_watchedRamdisks removeObjectForKey:ramdisk.volumeURL];
  [self _updateFilesystemCallback];
}

- (void)_unwatchAllRamdisks {
  [_watchedRamdisks removeAllObjects];
  [self _updateFilesystemCallback];
}

- (void)_changeWatchedRamdiskURL:(RMFRamdisk *)ramdisk oldURL:(NSURL *)oldURL newURL:(NSURL *)newURL {
  NSLog(@"%@: Updating new Volume URL for FSEvteens for ramdisk %@", [self class], ramdisk);
  [_watchedRamdisks removeObjectForKey:oldURL];
  _watchedRamdisks[newURL] = ramdisk;
  [self _updateFilesystemCallback];
}

@end

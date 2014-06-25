//
//  LSCoreDataManager.m
//  LSCoreDataManager
//
//  Created by Luca Serpico on 23/06/2014.
//  Copyright (c) 2014 Luca Serpico. All rights reserved.
//

#import "LSCoreDataManager.h"
#import <CoreData/CoreData.h>

@interface LSCoreDataManager()

@property (strong, nonatomic) NSManagedObjectContext       *privateWriterContext;
@property (strong, nonatomic) NSManagedObjectModel         *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSURL *modelURL;
@property (strong, nonatomic) NSURL *storeURL;

@end

@implementation LSCoreDataManager
@synthesize mainObjectContext = _mainObjectContext;

+(LSCoreDataManager*)sharedInstance{
    static LSCoreDataManager *sharedInstance;
    
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        sharedInstance = [[LSCoreDataManager alloc] init];
    });
    return sharedInstance;
}
-(id)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeToDisk) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeToDisk) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writeToDisk) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}


#pragma mark - Core Data Setup
-(void)setupWithModelUrl:(NSURL*)modelURL storeUrl:(NSURL*)storeURL{
    self.modelURL = modelURL;
    self.storeURL = storeURL;
    [self _setupCoreDataStack];
}

- (void)_setupCoreDataStack{
    //Setup managed object model
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:_modelURL];
    
    //Setup persistent store coordinator
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
                               NSInferMappingModelAutomaticallyOption : @YES};
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // subscribe to change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

#pragma mark - Getter
-(NSManagedObjectContext*)getNewContext{
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = _mainObjectContext;
    temporaryContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    [temporaryContext setUndoManager:nil];
    return temporaryContext;
}

-(NSManagedObjectContext*)privateWriterContext{
    @synchronized(self){
        if (_privateWriterContext)
            return _privateWriterContext;
        _privateWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_privateWriterContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
        return _privateWriterContext;
    }
}
-(NSManagedObjectContext*)mainObjectContext{
    @synchronized(self){
        if (_mainObjectContext)
            return _mainObjectContext;
        _mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainObjectContext.parentContext = self.privateWriterContext;
        return _mainObjectContext;
    }
}

#pragma mark - Notification 
- (void)_mocDidSaveNotification:(NSNotification *)notification{
    NSManagedObjectContext *savedContext = [notification object];
    
    // Ignore change notifications for the main MOC
    if (_mainObjectContext == savedContext){
        return;
    }
    
    if (_mainObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator){
        // that's another database
        return;
    }
    
    [_mainObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

#pragma mark - Public methods
- (void)saveContext:(NSManagedObjectContext *)context async:(BOOL)async{
    if (async) {
        [context performBlock:^{
            NSError *error;
            if ([context hasChanges] && ![context save:&error])
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }];
    }else{
        [context performBlockAndWait:^{
            NSError *error;
            if ([context hasChanges] && ![context save:&error])
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }];
    }
}
- (void)writeToDisk{
    NSManagedObjectContext *writeManagedObjectContext = self.privateWriterContext;
    NSManagedObjectContext *mainManagedObjectContext = self.mainObjectContext;
    
    [mainManagedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        if ([mainManagedObjectContext hasChanges] && ![mainManagedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        
        [writeManagedObjectContext performBlock:^{
            NSError *error = nil;
            if ([writeManagedObjectContext hasChanges] && ![writeManagedObjectContext save:&error])
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
        }];
        
    }];
}
@end
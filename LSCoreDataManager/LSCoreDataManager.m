//
//  LSCoreDataManager.m
//  LSCoreDataManager
//
//  Created by Luca Serpico on 23/06/2014.
//  Copyright (c) 2014 Luca Serpico. All rights reserved.
//

#import "LSCoreDataManager.h"

@interface LSCoreDataManager()

@property (strong, nonatomic) NSManagedObjectContext       *privateWriterContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *mainObjectContext;
@property (strong, nonatomic,readwrite) NSManagedObjectModel *managedObjectModel;
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
}

#pragma mark - Getter
-(NSManagedObjectContext*)getNewContext{
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainObjectContext;
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

#pragma mark - Public methods
- (void)saveContext:(NSManagedObjectContext *)context{
	NSParameterAssert(context.persistentStoreCoordinator == self.persistentStoreCoordinator);
	__block NSError *error;
	
	if (context == self.mainObjectContext) {
		[self.mainObjectContext performBlock:^{
			if (![self.mainObjectContext save:&error])
				NSLog(@"Error %@", error.description);
			else{
				[self.privateWriterContext performBlock:^{
					if (![self.privateWriterContext save:&error])
						NSLog(@"Error %@", error.description);
				}];
			}
		}];
	}else{
		[context performBlock:^{
			if (![context save:&error])
				NSLog(@"Error %@", error.description);
			else{
				[self.mainObjectContext performBlock:^{
					if (![self.mainObjectContext save:&error])
						NSLog(@"Error %@", error.description);
					else{
						[self.privateWriterContext performBlock:^{
							if (![self.privateWriterContext save:&error])
								NSLog(@"Error %@", error.description);
						}];
					}
				}];
			}
		}];
	}
	
}

@end

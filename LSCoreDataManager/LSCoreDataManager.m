//
//  LSCoreDataManager.m
//  LSCoreDataManager
//
//  Created by Luca Serpico on 23/06/2014.
//  Copyright (c) 2014 Luca Serpico. All rights reserved.
//

#import "LSCoreDataManager.h"

@interface LSCoreDataManager()

@property (strong, nonatomic) NSURL *storeUrl;
@property (strong, nonatomic) NSURL *modelUrl;
@property (strong, nonatomic, readwrite) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSManagedObjectContext *privateWriterContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *mainObjectContext;

@end

@implementation LSCoreDataManager

+ (LSCoreDataManager*)sharedInstance{
    static LSCoreDataManager *sharedInstance;
    
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        sharedInstance = [[LSCoreDataManager alloc] init];
    });
    return sharedInstance;
}

- (void)setupWithModelUrl:(NSURL*)modelURL storeUrl:(NSURL*)storeURL{
	self.modelUrl = modelURL;
	self.storeUrl = storeURL;
}

- (instancetype)initWithWithModelUrl:(NSURL*)modelURL storeUrl:(NSURL*)storeURL{
	self = [super init];
	if (self){
		self.modelUrl = modelURL;
		self.storeUrl = storeURL;
	}
	return self;
}

#pragma mark - Core Data Setup
// Used to propegate saves to the persistent store (disk) without blocking the UI
- (NSManagedObjectContext*)privateWriterContext{
	@synchronized(self){
		if (!_privateWriterContext) {
			NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
			if (coordinator != nil) {
				_privateWriterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
				[_privateWriterContext performBlockAndWait:^{
					[_privateWriterContext setPersistentStoreCoordinator:coordinator];
				}];
			}
		}
		return _privateWriterContext;
	}
}

// Context on the NSMainQueueConcurrencyType. Use this for the things to show
- (NSManagedObjectContext *)mainObjectContext {
	@synchronized(self){
		if (!_mainObjectContext) {
			NSManagedObjectContext *writerContext = self.privateWriterContext;
			if (writerContext != nil) {
				_mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
				[_mainObjectContext performBlockAndWait:^{
					[_mainObjectContext setParentContext:writerContext];
				}];
			}
		}
		return _mainObjectContext;
	}
}

#pragma mark - Saving Helper
- (NSManagedObjectContext *)temporaryContext {
	NSManagedObjectContext *newContext = nil;
	NSManagedObjectContext *masterContext = [self mainObjectContext];
	if (masterContext != nil) {
		newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[newContext performBlockAndWait:^{
			[newContext setParentContext:masterContext];
		}];
	}
	
	return newContext;
}


- (void)saveContext:(NSManagedObjectContext *)context{
	NSParameterAssert(context.persistentStoreCoordinator == self.persistentStoreCoordinator);
	__block NSError *error;
	
	if (context == self.mainObjectContext) {
		[self.mainObjectContext performBlockAndWait:^{
			if (![self.mainObjectContext save:&error]){
				NSLog(@"Error %@", error.description);
			}else{
				[self.privateWriterContext performBlock:^{
					if (![self.privateWriterContext save:&error]){
						NSLog(@"Error %@", error.description);
					}
				}];
			}
		}];
	}else{
		[context performBlockAndWait:^{
			if (![context save:&error]){
				NSLog(@"Error %@", error.description);
			}else{
				[self.mainObjectContext performBlockAndWait:^{
					if (![self.mainObjectContext save:&error]){
						NSLog(@"Error %@", error.description);
					}else{
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

#pragma mark - Persistency

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
	@synchronized(self){
		if (_managedObjectModel != nil) {
			return _managedObjectModel;
		}
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelUrl];
		return _managedObjectModel;
	}
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator{
	@synchronized(self){
		if (_persistentStoreCoordinator != nil) {
			return _persistentStoreCoordinator;
		}
		
		//Setup persistent store coordinator
		NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
								   NSInferMappingModelAutomaticallyOption : @YES};
		NSError *error = nil;
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeUrl options:options error:&error]) {
			// If the store is not compatible delete the stored items instead of crash
			if ([self storeRequireMigration:_persistentStoreCoordinator storeUrl:self.storeUrl]) {
#ifdef DEBUG
				NSLog(@"[LSCoreDataManager] Migration required - Unresolved errors %@, %@",error, [error userInfo]);
				abort();
#endif
				// Force Abort() in Debug mode. It works in release mode.
				// Note: Is better to implement a custom migration instead of delete all and recreate again
				[self removeStoreAtUrl:self.storeUrl];
				
				if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeUrl options:options error:&error]) {
					NSLog(@"[LSCoreDataManager] Unresolved errors %@, %@",error, [error userInfo]);
					abort();
				}
			}
		}
		
		return _persistentStoreCoordinator;
	}
}

#pragma mark - Helpers
- (BOOL)storeRequireMigration:(NSPersistentStoreCoordinator*)storeCoordinator storeUrl:(NSURL*)storeUrl{
	NSError *error = nil;
	
	// Determine if a migration is needed
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeUrl error:&error];
	NSManagedObjectModel *destinationModel = [storeCoordinator managedObjectModel];
	BOOL pscCompatibile = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
	
	return !pscCompatibile;
}

- (void)removeStoreAtUrl:(NSURL*)storeUrl{
	NSError *error;
	[[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&error];
}

@end

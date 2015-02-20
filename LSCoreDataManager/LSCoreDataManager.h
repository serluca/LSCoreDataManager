//
//  LSCoreDataManager.h
//  LSCoreDataManager
//
//  Created by Luca Serpico on 23/06/2014.
//  Copyright (c) 2014 Luca Serpico. All rights reserved
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 *  This is the Main Class of this library. 
 *	Please note: this app also prevent the crashs in the release mode when a migration is required
 *	Using the preprocessor query DEBUG the app invoke abort only in debug mode.
 *
 *	You can use this class using the singleton or allocating it if you have more than one Core Data File
 */

@interface LSCoreDataManager : NSObject

/** The main context */
@property (strong, nonatomic, readonly) NSManagedObjectContext *mainObjectContext;
/** The managed object model */
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
/** The persistent store coordinator */
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/** Retrieve the singleton instance */
+ (LSCoreDataManager*)sharedInstance;

/**
 *  Invokes this method in the app delegate to configure the manager
 *
 *  @param modelURL The model's URL
 *  @param storeURL The store's URL
 */
-(void)setupWithModelUrl:(NSURL*)modelURL storeUrl:(NSURL*)storeURL;

/**
 *  Create an setup an instance of LSCoreDataManager
 *
 *  @param fileName The name of the your xcdatamodeld file
 *  @param bundle The budle of the your xcdatamodeld file
 *
 *  @return An instance of LSCoreDataManager
 */
- (instancetype)initWithWithModelUrl:(NSURL*)modelURL storeUrl:(NSURL*)storeURL;

/**
 *  Ask for a temporary context.
 *  Everything that happens in this context will have no effect on the Main Context
 *  Until will not be invoked a saves for it
 *
 *  @return A new temporary Context with concurrencyType NSPrivateQueueConcurrencyType
 */
- (NSManagedObjectContext*)temporaryContext;

/**
 *  Save a context if it has changes
 *
 *  @param context The context that you want to say
 */
- (void)saveContext:(NSManagedObjectContext *)context;

@end

//
//  LSCoreDataManager.h
//  LSCoreDataManager
//
//  Created by Luca Serpico on 23/06/2014.
//  Copyright (c) 2014 Luca Serpico. All rights reserved
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LSCoreDataManager : NSObject

/**
 *  The main context
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *mainObjectContext;

/**
 *  The object Model
 */
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;

+(LSCoreDataManager*)sharedInstance;

/**
 *  Invokes this method in the app delegate to configure the manager
 *
 *  @param modelURL The model's URL
 *  @param storeURL The store's URL
 */
-(void)setupWithModelUrl:(NSURL*)modelURL storeUrl:(NSURL*)storeURL;

/**
 *  Ask for a new context.
 *  Everything that happens in this context will have no effect on the Main Context 
 *  Before that will not be invoked a saves for it
 *
 *  @return A new Private Context
 */
-(NSManagedObjectContext*)getNewContext;

/**
 *  Save a context if it has changes
 *
 *  @param context The context that you want to say
 */

@end

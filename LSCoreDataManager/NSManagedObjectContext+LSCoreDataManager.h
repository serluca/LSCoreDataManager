//
//  NSManagedObjectContext+LSCoreDataManager.h
//  LSCoreDataManager
//
//  Created by Luca Serpico on 21/02/2015.
//  Copyright (c) 2015 Luca Serpico. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (LSCoreDataManager)

- (NSFetchRequest *)fetchRequestForEntityNamed:(NSString *)entityName
								  sortedByKeys:(NSArray *)keys
								fetchBatchSize:(NSUInteger)fetchBatchSize;

- (NSFetchedResultsController *)fetchedResultsControllerForEntityNamed:entityName
														  sortedByKeys:(NSArray *)keys
														fetchBatchSize:(NSUInteger) fetchBatchSize
													sectionNameKeyPath:(NSString *)sectionNameKeyPath
															 cacheName:(NSString *)cacheName;
@end

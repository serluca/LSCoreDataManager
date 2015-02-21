//
//  NSManagedObjectContext+LSCoreDataManager.m
//  LSCoreDataManager
//
//  Created by Luca Serpico on 21/02/2015.
//  Copyright (c) 2015 Luca Serpico. All rights reserved.
//

#import "NSManagedObjectContext+LSCoreDataManager.h"

@implementation NSManagedObjectContext (LSCoreDataManager)
- (NSFetchRequest *)fetchRequestForEntityNamed:(NSString *)entityName
								  sortedByKeys:(NSArray *)keys
								fetchBatchSize:(NSUInteger)fetchBatchSize {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
	[fetchRequest setEntity:entity];
	
	[fetchRequest setFetchBatchSize:fetchBatchSize];
	
	NSMutableArray *sortDescriptors = [NSMutableArray arrayWithCapacity:[keys count]];
	NSString *key;
	for (key in keys) {
		BOOL ascending = YES;
		if ([key characterAtIndex:0] == '-') {
			ascending = NO;
			key = [key substringFromIndex:1];
		}
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:ascending];
		[sortDescriptors addObject:sortDescriptor];
	}
	
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	return fetchRequest;
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntityNamed:entityName
														  sortedByKeys:(NSArray *)keys
														fetchBatchSize:(NSUInteger) fetchBatchSize
													sectionNameKeyPath:(NSString *)sectionNameKeyPath
															 cacheName:(NSString *)cacheName {
	NSFetchRequest *fetchRequest = [self fetchRequestForEntityNamed:entityName sortedByKeys:keys fetchBatchSize:fetchBatchSize];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self sectionNameKeyPath:sectionNameKeyPath cacheName:cacheName];
	return fetchedResultsController;
}

@end

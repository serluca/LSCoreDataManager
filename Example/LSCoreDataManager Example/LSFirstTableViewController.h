//
//  LSFirstTableViewController.h
//  LSCoreDataManager
//
//  Created by Luca Serpico on 26/06/2014.
//  Copyright (c) 2014 Luca Serpico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface LSFirstTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

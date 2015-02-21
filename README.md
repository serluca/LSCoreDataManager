LSCoreDataManager
=================

Is a nice library to manage the Core Data simplifying the developer's task  in performance management. The biggest impact in the Core Data's uses is mainly due to when you save to disk and when making large transactions on the main context. This library helps the developer to use to a minimum the main context and saving the data on the disk, increasing the performances of the app than normal uses.

##How to Get Started
Download the project and imports the files `LSCoreDataManager.h` and `LSCoreDataManager.m` into your project 
###Installation with CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like LSCoreDataManager in your projects.
###Podfile
    platform :ios, '7.0'
    pod "LSCoreDataManager"

##Usage
Create a new project without Core Data, after go in the menu "File -> New -> File" on the left side select "Core Data", create a new data model and name it for example "LSModel".
Now includes the library in the project, as has been described above and put in your AppDelegate.m this code:

`#import "LSCoreDataManager.h"`

and put this in `application:didFinishLaunchingWithOptions:`


    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LSModel" withExtension:@"momd"];
    
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"LSModel.sqlite"];
    
    [[LSCoreDataManager sharedInstance] setupWithModelUrl:modelURL storeUrl:storeURL];
    
Now your Core Data is ready, just need to import LSCoreDataManager.h in all the classes in which you want to use it.

###Best practices
Use the main context only for fetch requests or tries to minimize the operations of insertion, modification and deletion on it, use a temporary context getting it by `getNewContext`. When you save a temporary context the changes are automatically shown in the main context. This will improve greatly your performance.

Note:

Store always the contexts in your variables. Using the context by invoking them from the manager cause a memory leak. Look the example: `self.context = [[LSCoreDataManager sharedInstance] mainObjectContext];`

Use always the method `saveContext:` to save all your context. Everything is saved avoiding to block the UI.

The logic of this class follows the logic described in this article: [http://www.cocoanetics.com/2012/07/multi-context-coredata/](http://www.cocoanetics.com/2012/07/multi-context-coredata/) and also include some code from [http://nuthole.com/blog/2012/11/07/could-core-data-be-a-little-more-concise/](http://nuthole.com/blog/2012/11/07/could-core-data-be-a-little-more-concise/)
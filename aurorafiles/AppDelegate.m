//
//  AppDelegate.m
//  aurorafiles
//
//  Created by Michael Akopyants on 08/07/15.
//  Copyright (c) 2015 Michael Akopyants. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <BugfenderSDK/BugfenderSDK.h>
#import "MLNetworkLogger.h"
#import "AFNetworkActivityLogger.h"

#import <MagicalRecord/MagicalRecord.h>

#import "StorageManager.h"
#import "DataBaseProvider.h"
#import "MRDataBaseProvider.h"
#import "FileOperationsProvider.h"
#import "IDataBaseProtocol.h"

#import "SessionProvider.h"
#import "Settings.h"
//#import <CocoaLumberjack/CocoaLumberjack.h>
//#define LOG_LEVEL_DEF ddLogLevel

@interface AppDelegate (){

}

@property (nonatomic) id<IDataBaseProtocol> dbProvider;
@property (nonatomic) id<IDataBaseProtocol> settingsDBProvider;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [Fabric with:@[[Crashlytics class]]];
    [CrashlyticsKit setDebugMode:YES];
    
    [self configureLogger];
    
    self.dbProvider = [DataBaseProvider init];
    [self.dbProvider setupCoreDataStack];
    [[StorageManager sharedManager]setupDBProvider:self.dbProvider];
    [[StorageManager sharedManager]setupFileOperationsProvider:[FileOperationsProvider sharedProvider]];

//    [self.dbProvider removeAll];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [Settings saveSettings];
    [self.dbProvider endWork];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [Settings saveSettings];
    [self.dbProvider endWork];
    
}

#pragma mark - Loggers

- (void)configureLogger{
#ifdef DEBUG
    static const AFHTTPRequestLoggerLevel networlLogLevel = AFLoggerLevelDebug;
#else
    static const AFHTTPRequestLoggerLevel networlLogLevel = AFLoggerLevelWarn;
#endif
    
    [self configureMainLogger:ddLogLevel];
    [self configureNetworkLogger:networlLogLevel];
    [self configureRemoteLogging];
    
}

- (void)configureMainLogger:(DDLogLevel)logLevel{
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:logLevel];
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:logLevel];
}

- (void)configureNetworkLogger:(AFHTTPRequestLoggerLevel)logLevel{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:logLevel];
}

- (void)configureRemoteLogging{
    [Bugfender enableAllWithToken:@"XjOPlmw9neXecfebLqUwiSfKOCLxwCHT"];
}

@end

//
//  aurorafilesUITests.m
//  aurorafilesUITests
//
//  Created by Michael Akopyants on 07/06/16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface aurorafilesUITests : XCTestCase{
    XCUIApplication *app;
}

@end

@implementation aurorafilesUITests

- (void)setUp {
    [super setUp];
//    self.continueAfterFailure = NO;
//    app = [[XCUIApplication alloc] init];
//    [app launch];
//    [[XCUIDevice sharedDevice] setOrientation:UIDeviceOrientationFaceUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLogin{
    NSString *host = @"p7.afterlogic.com";
    NSString *login = @"a.kovalev@afterlogic.com";
    NSString *password = @"starwars1992";
    
//    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *elementsQuery = app.scrollViews.otherElements;
    
    if ([app.toolbars.buttons[@"more"]exists]){
        [app.toolbars.buttons[@"more"]tap];
        [app.sheets[@"Choose option"].buttons[@"Logout"] tap];
    }
    
    XCUIElement *hostTextField = elementsQuery.textFields[@"Host"];
    [hostTextField tap];
    
    XCUIElement *deleteKey = app.keys[@"delete"];
    [deleteKey pressForDuration:5.0];
    
    
    XCUIElement *emailTextField = elementsQuery.textFields[@"Email"];
    [emailTextField tap];
    [deleteKey pressForDuration:5.0];
    
    XCUIElement *passwordSecureTextField = elementsQuery.secureTextFields[@"Password"];
    [passwordSecureTextField tap];
    [deleteKey pressForDuration:5.0];
    [hostTextField tap];
    [hostTextField typeText:host];
    [emailTextField tap];
    [emailTextField typeText:login];
    [passwordSecureTextField tap];
    [passwordSecureTextField typeText:password];
    [elementsQuery.buttons[@"Sign In"] tap];

//    XCTAssertFalse([app.toolbars.buttons[@"more"] exists]);
    
}

- (void)testLogout{
//    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    if (![app.toolbars.buttons[@"more"]exists]){
        [self testLogin];
    }
    
    [app.toolbars.buttons[@"more"]tap];
    [app.sheets[@"Choose option"].buttons[@"Logout"] tap];
    

}

- (void)testChangeRootDirectory{
    const int iterator = 3;
//    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    XCUIElement *moreButtonLabel = app.staticTexts[@"more"];
    
    XCTestCase *testCase = [[XCTestCase alloc]init];
    NSPredicate *existPredicate = [NSPredicate predicateWithFormat:@"exists == true"];
    [testCase expectationForPredicate:existPredicate evaluatedWithObject:moreButtonLabel handler:nil];
    [testCase waitForExpectationsWithTimeout:10 handler:nil];
    
    
    BOOL moreButtonExisted = [app.toolbars.buttons[@"more"]exists];
    if (!moreButtonExisted){
        [self testLogin];
    }
    
    for (int i = 0; i <= iterator; i++) {
        [app.buttons[@"Corporate"] tap];
        
        [app.buttons[@"Personal"] tap];
    }
}

- (void)testOpenFolder{
    XCUIElement *moreButtonLabel = app.staticTexts[@"more"];
    
    XCTestCase *testCase = [[XCTestCase alloc]init];
    NSPredicate *existPredicate = [NSPredicate predicateWithFormat:@"exists == true"];
    [testCase expectationForPredicate:existPredicate evaluatedWithObject:moreButtonLabel handler:nil];
    [testCase waitForExpectationsWithTimeout:10 handler:nil];
    
    
    BOOL moreButtonExisted = [app.toolbars.buttons[@"more"]exists];
    if (!moreButtonExisted){
        [self testLogin];
    }
    
    
    XCUIElementQuery *tablesQuery = [[XCUIApplication alloc] init].tables;
    [tablesQuery.staticTexts[@"Картинки"] tap];
    
    XCUIElement *imageLabel = app.staticTexts[@"eat2.png"];
    XCTestCase *openFolderCase = [[XCTestCase alloc]init];
    [openFolderCase expectationForPredicate:existPredicate evaluatedWithObject:imageLabel handler:nil];
    [openFolderCase waitForExpectationsWithTimeout:10 handler:nil];
    
    [tablesQuery.staticTexts[@"eat2.png"] tap];
    
}

- (void)testOpenPicture{
    
}




@end

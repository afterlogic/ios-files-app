//
//  snapshotTest.swift
//  snapshotTest
//
//  Created by Cheshire on 07.10.16.
//  Copyright © 2016 afterlogic. All rights reserved.
//

import XCTest
//import SnapshotHelper

class snapshotTest: XCTestCase {
    
    let p7Host:String        = "p7.afterlogic.com"
    let p8DevHost:String     = "cloudtest.afterlogic.com"
    
    let defaultLogin:String  = "a.kovalev@afterlogic.com"
    let p7Password:String = "starwars1992"
    let p8Password:String = "qwezxc"
    
    
    let snapshotHost: String = "aurora.afterlogic.com"
    let snapshotLog: String = "aurora@afterlogic.com"
    let snapshotPass: String = "qwezxc"
    
        
    override func setUp() {
        super.setUp()

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCUIDevice.shared().orientation = .faceUp
        XCUIDevice.shared().orientation = .faceUp
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        XCUIDevice.shared().orientation = .faceUp
        XCUIDevice.shared().orientation = .faceUp
        
        let elementsQuery = app.scrollViews.otherElements
        let hostTextField = elementsQuery.textFields["Host"]
        hostTextField.tap()
        
        let deleteKey = app.keys["delete"]
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.press(forDuration: 5.0);
        
        let emailTextField = elementsQuery.textFields["Email"]
        emailTextField.tap()
        deleteKey.press(forDuration: 5);
        hostTextField.tap()
        hostTextField.typeText(snapshotHost)
        emailTextField.tap()
        emailTextField.typeText(snapshotLog)
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(snapshotPass)
        
        let scrollViewsQuery = app.scrollViews
//        scrollViewsQuery.otherElements.containing(.textField, identifier:"Host").element.tap()
        
        
        snapshot("01LoginScreen")
        
        hostTextField.tap()
        deleteKey.press(forDuration: 5);
        hostTextField.typeText(p7Host)
        emailTextField.tap()
        deleteKey.press(forDuration: 5);
        emailTextField.typeText(defaultLogin)
        passwordSecureTextField.tap()
        deleteKey.press(forDuration: 0.6);
        deleteKey.press(forDuration: 0.6);
        passwordSecureTextField.typeText(p7Password)
        elementsQuery.buttons["Sign In"].tap()
        
        
        let tablesQuery = XCUIApplication().tables
        
        let needfulCell = app.tables.cells.element(boundBy: 5)
        let existPredicate = NSPredicate (format:"exists == true")
        
        expectation(for: existPredicate, evaluatedWith: needfulCell, handler: nil)
        waitForExpectations(timeout: 10, handler: nil);
        
        tablesQuery.cells.containing(.staticText, identifier:"IMG_0667.JPG").buttons["download"].tap()
        tablesQuery.cells.containing(.staticText, identifier:"InternetShortcut1475497935").buttons["download"].tap()
        
        
        snapshot("02Personal")
        
        XCUIApplication().buttons["Corporate"].tap()
        
        snapshot("03Corporate")
        
        XCUIApplication().toolbars.buttons["more"].tap()
        
        snapshot("04Options")
        
        XCUIApplication().sheets["Choose option"].buttons["Downloads"].tap()
        
        snapshot("05Downloads")
        
    }
}

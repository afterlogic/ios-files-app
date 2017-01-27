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
        deleteKey.press(forDuration: 2.0);
        
        let emailTextField = elementsQuery.textFields["Email"]
        emailTextField.tap()
        deleteKey.press(forDuration: 2.8);
        hostTextField.tap()
        hostTextField.typeText("aurora")
        
        let moreKey = app.keys["more"]
        moreKey.tap()
        moreKey.tap()
        hostTextField.typeText(".")
        
        let moreKey2 = app.keys["more"]
        moreKey2.tap()
        moreKey2.tap()
        hostTextField.typeText("afterlogic")
        moreKey.tap()
        hostTextField.typeText(".")
        moreKey2.tap()
        hostTextField.typeText("com")
        emailTextField.tap()
        emailTextField.typeText("aurora@afterlogic.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("qwezxc")
        
        
        snapshot("01LoginScreen")
        
        
        //        let elementsQuery = app.scrollViews.otherElements
        //        let hostTextField = elementsQuery.textFields["Host"]
        hostTextField.tap()
        
        //        let deleteKey = app.keys["delete"]
        deleteKey.press(forDuration: 2.6);
        hostTextField.typeText("p")
        
        //        let moreKey = app.keys["more"]
        moreKey.tap()
        moreKey.tap()
        hostTextField.typeText("7.")
        
        //        let moreKey2 = app.keys["more"]
        moreKey2.tap()
        moreKey2.tap()
        hostTextField.typeText("afterlogic")
        moreKey.tap()
        hostTextField.typeText(".")
        moreKey2.tap()
        hostTextField.typeText("com")
        
        //        let emailTextField = elementsQuery.textFields["Email"]
        emailTextField.tap()
        deleteKey.press(forDuration: 2.5);
        emailTextField.typeText("a.kovalev@afterlogic.com")
        
        //        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        deleteKey.press(forDuration: 0.6);
        deleteKey.press(forDuration: 0.6);
        passwordSecureTextField.typeText("starwars1992")
        elementsQuery.buttons["Sign In"].tap()
        
        snapshot("02Personal")
        
        XCUIApplication().buttons["Corporate"].tap()
        
        snapshot("03Corporate")
        
        XCUIApplication().toolbars.buttons["more"].tap()
        
        snapshot("04Options")
        
        XCUIApplication().sheets["Choose option"].buttons["Downloads"].tap()
        
        snapshot("05Downloads")
        
    }
}

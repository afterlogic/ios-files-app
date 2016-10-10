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
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        XCUIDevice.shared().orientation = .faceUp
        XCUIDevice.shared().orientation = .faceUp
        XCUIDevice.shared().orientation = .faceUp
        
        let elementsQuery = app.scrollViews.otherElements
        let deleteKey = app.keys["delete"]
        let hostTextField = elementsQuery.textFields["Host"]
        hostTextField.tap()
        XCUIDevice.shared().orientation = .portrait
        
        hostTextField.typeText("aurora.afterlogic.com")
        
        let moreKey = app.keys["more"]
        let emailTextField = elementsQuery.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("st")
        
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        emailTextField.typeText("aurora@afterlogic.com")
        

        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("starwarrs")
        moreKey.tap()
        passwordSecureTextField.typeText("1992")
        
        snapshot("01LoginScreen")
        
        let signInButton = elementsQuery.buttons["Sign In"]
        
        hostTextField.tap()
        deleteKey.press(forDuration: 3.6);
        hostTextField.typeText("p7.afterlogic.com")
        
        emailTextField.tap()
        deleteKey.press(forDuration: 3.6);
        emailTextField.typeText("a.kovalev@afterlogic.com")
        
        passwordSecureTextField.tap()
        
        deleteKey.press(forDuration: 3.6);
        
        passwordSecureTextField.typeText("starwars1992")
        signInButton.tap()
        
        let tablesQuery2 = app.tables
        let img0667JpgStaticText = tablesQuery2.staticTexts["IMG_0667.JPG"]
        
        let tablesQuery = tablesQuery2
        img0667JpgStaticText.tap()
        let back = app.navigationBars.buttons["Personal"]
        back.tap()
        
        tablesQuery2.cells.containing(.staticText, identifier:"IMG_0667.JPG").children(matching: .staticText).matching(identifier: "IMG_0667.JPG").element(boundBy: 0).swipeUp()
        tablesQuery.cells.containing(.staticText, identifier:"IMG_0667.JPG").buttons["download"].tap()
        tablesQuery.cells.containing(.staticText, identifier:"InternetShortcut1475497935").buttons["download"].tap()
        snapshot("02Personal")

        let tabBarsQuery = app.tabBars
        let corporateButton = tabBarsQuery.buttons["Corporate"]
        corporateButton.tap()
        tablesQuery.staticTexts["ios client test"].swipeUp()
        snapshot("03Corporate")
        tablesQuery.staticTexts["AfterLogic Corporate Docs"].tap()
        app.navigationBars["AfterLogic Corporate Docs"].buttons["Corporate"].tap()

        tabBarsQuery.buttons["Downloads"].tap()
        snapshot("06Downloads")
        corporateButton.tap()
        app.navigationBars["Corporate"].buttons["more"].tap()
        
        let chooseOptionSheet = app.sheets["Choose option"]
        snapshot("04Options")
        
        let cancelButton = chooseOptionSheet.buttons["Cancel"]
        cancelButton.tap()
        tabBarsQuery.buttons["Personal"].tap()
        
        let moreButton = app.navigationBars["Personal"].buttons["more"]
        moreButton.tap()
        chooseOptionSheet.buttons["Create Folder"].tap()
        
        let enterNameAlert = app.alerts["Enter Name"]
        let folderNameTextField = enterNameAlert.collectionViews.textFields["Folder Name"]
        snapshot("05CreateFolder")
        folderNameTextField.typeText("s")
        folderNameTextField.typeText("a")
        folderNameTextField.typeText("me f")
        folderNameTextField.typeText("old")
        folderNameTextField.typeText("er")
        enterNameAlert.buttons["Create"].press(forDuration: 0.8);

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }
}

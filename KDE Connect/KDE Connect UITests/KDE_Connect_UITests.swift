/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

// Original header below:
//
//  KDE_Connect_UITests.swift
//  KDE Connect UITests
//
//  Created by Lucas Wang on 2021-06-17.
//

import XCTest

class KDE_Connect_UITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Take up to 10 screenshots for App Store release.
    func testTakeScreenshots() throws {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if isPad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["setupScreenshotDevices"]
        setupSnapshot(app)
        app.launch()
        
        func saveScreenshot(_ name: String) {
            snapshot(name)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        if !isPad {
            saveScreenshot("0. Home Screen")
        }

        app.tables.cells["McIntosh, 100%"].tap()
        saveScreenshot("1. Device Details")

        app.tables.buttons["Slideshow Remote"].tap()
        saveScreenshot("2. Slideshow Remote")

        app.navigationBars["Slideshow Remote"].buttons["McIntosh"].tap()
        app.tables.buttons["Run Command"].tap()
        saveScreenshot("3. Run Command")

        app.navigationBars["Run Command"].buttons["McIntosh"].tap()
        app.tables.buttons["Remote Input"].tap()
        if isPad {
            app.navigationBars["Remote Input"].buttons["More"].tap()
        }
        saveScreenshot("4. Remote Input")

        if isPad {
            app.buttons["Send Single Left Click"].tap()
        }
        app.tabBars["Tab Bar"].buttons["Settings"].tap()
        if isPad {
            app.tables.cells["Features"].tap()
        }
        saveScreenshot("5. Settings")

        app.tables.cells["About"].tap()
        saveScreenshot("6. About")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

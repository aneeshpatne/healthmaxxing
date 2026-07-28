//
//  FormaUITests.swift
//  FormaUITests
//
//  Created by Aneesh Patne on 19/06/26.
//

import XCTest

final class FormaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = launchShell(tab: "metrics")

        XCTAssertTrue(app.staticTexts["No report yet"].waitForExistence(timeout: 8))

        let recordMeasurement = app.buttons["Record Measurement"]
        XCTAssertTrue(recordMeasurement.exists)
        recordMeasurement.tap()

        XCTAssertTrue(app.buttons["Record"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testFeaturePreviewTabs() throws {
        let workouts = launchShell(tab: "workouts")
        XCTAssertTrue(workouts.staticTexts["COMING SOON"].waitForExistence(timeout: 8))
        XCTAssertTrue(
            workouts.staticTexts[
                "Guided strength sessions and training analytics are being shaped for a future update."
            ].exists
        )
        workouts.terminate()

        let vitals = launchShell(tab: "vitals")
        XCTAssertTrue(vitals.staticTexts["COMING SOON"].waitForExistence(timeout: 8))
        XCTAssertTrue(
            vitals.staticTexts[
                "Heart-rate history, recovery, and Apple Health trends are being prepared for a future update."
            ].exists
        )
    }

    @MainActor
    func testRecordTabShowsExplicitAction() throws {
        let app = launchShell(tab: "record")

        XCTAssertTrue(app.buttons["Record"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.buttons["Record"].value as? String, "Ready")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func launchShell(tab: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-FormaUITestShell", "-FormaUITestTab", tab]
        app.launch()
        return app
    }
}

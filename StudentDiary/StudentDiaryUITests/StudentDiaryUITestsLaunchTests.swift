//
//  StudentDiaryUITestsLaunchTests.swift
//  StudentDiaryUITests
//
//  Created by Ксения Наклонная on 03.06.2025.
//

import XCTest

final class StudentDiaryUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Проверяем, что приложение запустилось
        XCTAssertTrue(app.exists, "Приложение должно существовать после запуска")
        
        // Проверяем, что виден экран входа
        let loginScreen = app.staticTexts["Student Diary"]
        let exists = loginScreen.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Логотип Student Diary должен отображаться на экране входа")
        
        // Проверяем, что все основные элементы видны на экране
        let loginButton = app.buttons["Вход"]
        let registerButton = app.buttons["Регистрация"]
        
        XCTAssertTrue(loginButton.exists, "Кнопка 'Вход' должна быть видна")
        XCTAssertTrue(registerButton.exists, "Кнопка 'Регистрация' должна быть видна")
        
        // Делаем скриншот для отчёта
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchWithArguments() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
        
        // Проверяем, что приложение запустилось с аргументами
        XCTAssertTrue(app.exists, "Приложение должно запускаться с аргументами")
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            // Измеряем время запуска приложения
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let app = XCUIApplication()
                app.launch()
            }
        }
    }
}

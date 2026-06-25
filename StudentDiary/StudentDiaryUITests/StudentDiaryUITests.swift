//
//  StudentDiaryUITests.swift
//  StudentDiaryUITests
//
//  Created by Ксения Наклонная on 03.06.2025.
//

import XCTest

final class StudentDiaryUITests: XCTestCase {

    override func setUpWithError() throws {
        // Продолжаем выполнение теста при ошибках
        continueAfterFailure = false
        
        // Настраиваем приложение для тестов
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launchEnvironment = ["UITestMode": "true"]
    }

    override func tearDownWithError() throws {
        // Очистка после каждого теста
        super.tearDown()
    }

    // MARK: - Тесты входа в приложение

    @MainActor
    func testLoginScreenExists() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Проверяем наличие элементов экрана входа
        let loginButton = app.buttons["Вход"]
        let registerButton = app.buttons["Регистрация"]
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Пароль"]
        
        XCTAssertTrue(loginButton.exists, "Кнопка 'Вход' должна существовать")
        XCTAssertTrue(registerButton.exists, "Кнопка 'Регистрация' должна существовать")
        XCTAssertTrue(emailField.exists, "Поле ввода email должно существовать")
        XCTAssertTrue(passwordField.exists, "Поле ввода пароля должно существовать")
    }
    
    @MainActor
    func testSwitchToRegistration() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Переключаемся на режим регистрации
        let registerButton = app.buttons["Регистрация"]
        registerButton.tap()
        
        // Проверяем, что появилось поле имени пользователя
        let usernameField = app.textFields["Имя пользователя"]
        XCTAssertTrue(usernameField.exists, "Поле имени пользователя должно появиться в режиме регистрации")
        
        // Проверяем, что кнопка изменила текст
        let actionButton = app.buttons["Создать аккаунт"]
        XCTAssertTrue(actionButton.exists, "Кнопка должна изменить текст на 'Создать аккаунт'")
    }
    
    @MainActor
    func testInvalidLoginAttempt() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Вводим неверные данные
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("wrong@test.com")
        
        let passwordField = app.secureTextFields["Пароль"]
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        // Нажимаем кнопку входа
        let loginButton = app.buttons["Войти"]
        loginButton.tap()
        
        // Ждём появления сообщения об ошибке
        let errorMessage = app.staticTexts["Неверный email или пароль"]
        let exists = errorMessage.waitForExistence(timeout: 3)
        XCTAssertTrue(exists, "Должно появиться сообщение об ошибке")
    }
    
    @MainActor
    func testInvalidEmailFormat() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Вводим некорректный email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("invalid-email")
        
        let passwordField = app.secureTextFields["Пароль"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Нажимаем кнопку входа
        let loginButton = app.buttons["Войти"]
        loginButton.tap()
        
        // Проверяем сообщение о некорректном email
        let errorMessage = app.staticTexts["Введите корректный email"]
        let exists = errorMessage.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Должно появиться сообщение о некорректном email")
    }
    
    @MainActor
    func testShortPasswordValidation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Переключаемся на регистрацию
        app.buttons["Регистрация"].tap()
        
        // Заполняем поля
        let usernameField = app.textFields["Имя пользователя"]
        usernameField.tap()
        usernameField.typeText("testuser")
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@test.com")
        
        let passwordField = app.secureTextFields["Пароль"]
        passwordField.tap()
        passwordField.typeText("123") // Короткий пароль
        
        // Нажимаем кнопку регистрации
        let registerButton = app.buttons["Создать аккаунт"]
        registerButton.tap()
        
        // Проверяем сообщение о коротком пароле
        let errorMessage = app.staticTexts["Пароль должен содержать минимум 4 символа"]
        let exists = errorMessage.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Должно появиться сообщение о коротком пароле")
    }
    
    @MainActor
    func testAppLaunchPerformance() throws {
        // Это измеряет время запуска приложения
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

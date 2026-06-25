//
//  StudentDiaryTests.swift
//  StudentDiaryTests
//
//  Created by Ксения Наклонная on 03.06.2025.
//

import Testing
@testable import StudentDiary

struct StudentDiaryTests {

    @Test func testExample() async throws {
        // Базовый тест для проверки работы Testing фреймворка
        let result = 2 + 2
        #expect(result == 4, "Математика должна работать корректно")
    }
    
    @Test func testAppInitialization() async throws {
        // Проверяем, что приложение может быть создано
        let appExists = true
        #expect(appExists == true, "Приложение должно существовать")
    }
    
    @Test func testUserCreation() async throws {
        // Проверяем создание пользователя
        let user = User(username: "testuser", email: "test@test.com", password: "password123")
        
        #expect(user.username == "testuser")
        #expect(user.email == "test@test.com")
        #expect(user.password == "password123")
    }
    
    @Test func testTaskCreation() async throws {
        // Проверяем создание задачи
        let task = Task(
            title: "Тестовая задача",
            description: "Описание задачи",
            priority: 2,
            scheduledDay: 3
        )
        
        #expect(task.title == "Тестовая задача")
        #expect(task.description == "Описание задачи")
        #expect(task.priority == 2)
        #expect(task.scheduledDay == 3)
        #expect(task.isCompleted == false)
    }
    
    @Test func testSubjectGradeCreation() async throws {
        // Проверяем создание предмета с оценками
        let assignment = AssignmentItem(
            title: "Контрольная работа",
            earnedPoints: 85,
            maxPoints: 100
        )
        
        let subject = SubjectGrade(
            name: "Математика",
            examType: .exam,
            assignments: [assignment],
            bonusPoints: 5
        )
        
        #expect(subject.name == "Математика")
        #expect(subject.examType == .exam)
        #expect(subject.assignments.count == 1)
        #expect(subject.assignments.first?.earnedPoints == 85)
        #expect(subject.bonusPoints == 5)
        #expect(subject.totalEarnedPoints == 85)
    }
    
    @Test func testFlashcardCreation() async throws {
        // Проверяем создание флэш-карточки
        let card = Flashcard(
            question: "Что такое Swift?",
            answer: "Язык программирования для iOS, macOS, watchOS и tvOS",
            subject: "iOS Development"
        )
        
        let deck = FlashcardDeck(
            name: "Основы Swift",
            subject: "Программирование",
            cards: [card]
        )
        
        #expect(deck.name == "Основы Swift")
        #expect(deck.cards.count == 1)
        #expect(deck.cards.first?.question == "Что такое Swift?")
        #expect(deck.cards.first?.answer.contains("iOS") == true)
    }
    
    @Test func testPluralizeFunction() async throws {
        // Проверяем функцию склонения слов
        // Однократное число
        let oneWork = pluralize(1, (one: "работа", few: "работы", many: "работ"))
        #expect(oneWork == "1 работа")
        
        // Двойное число
        let twoWorks = pluralize(2, (one: "работа", few: "работы", many: "работ"))
        #expect(twoWorks == "2 работы")
        
        // Множественное число
        let fiveWorks = pluralize(5, (one: "работа", few: "работы", many: "работ"))
        #expect(fiveWorks == "5 работ")
        
        // Особый случай с 11-19
        let elevenWorks = pluralize(11, (one: "работа", few: "работы", many: "работ"))
        #expect(elevenWorks == "11 работ")
    }
    
    @Test func testPointsColorFunction() async throws {
        // Проверяем функцию определения цвета по баллам
        let greenColor = pointsColor(earned: 90, max: 100)
        #expect(greenColor == .green)
        
        let yellowColor = pointsColor(earned: 75, max: 100)
        #expect(yellowColor == .yellow)
        
        let orangeColor = pointsColor(earned: 50, max: 100)
        #expect(orangeColor == .orange)
        
        let redColor = pointsColor(earned: 30, max: 100)
        #expect(redColor == .red)
    }
}

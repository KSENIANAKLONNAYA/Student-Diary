import Foundation
import SwiftUI

class APIManager {
    static let shared = APIManager()
    
    private let baseURL = "http://localhost:8000/api"
    private var authToken: String? // Для авторизации
    
    private init() {}
    
    // MARK: - Авторизация
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    private func makeRequest<T: Decodable>(_ endpoint: String,
                                           method: String = "GET",
                                           body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Аутентификация
    func register(username: String, email: String, password: String) async throws -> User {
        let body: [String: Any] = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        let response: LoginResponse = try await makeRequest("register", method: "POST", body: body)
        return User(username: response.username, email: response.email, password: password)
    }
    
    func login(email: String, password: String) async throws -> (user: User, token: String) {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        let response: LoginResponse = try await makeRequest("login", method: "POST", body: body)
        return (User(username: response.username, email: response.email, password: password), response.token)
    }
    
    // MARK: - Задачи (Tasks)
    func getTasks() async throws -> [Task] {
        let response: [TaskResponse] = try await makeRequest("tasks")
        return response.map { $0.toTask() }
    }
    
    func createTask(_ task: Task) async throws -> Task {
        let body: [String: Any] = [
            "title": task.title,
            "description": task.description,
            "deadline": task.deadline?.timeIntervalSince1970 ?? 0,
            "isReminder": task.isReminder,
            "priority": task.priority,
            "scheduledDay": task.scheduledDay ?? 0,
            "isCompleted": task.isCompleted
        ]
        
        let response: TaskResponse = try await makeRequest("tasks", method: "POST", body: body)
        return response.toTask()
    }
    
    func updateTask(_ task: Task) async throws -> Task {
        let body: [String: Any] = [
            "title": task.title,
            "description": task.description,
            "deadline": task.deadline?.timeIntervalSince1970 ?? 0,
            "isReminder": task.isReminder,
            "priority": task.priority,
            "scheduledDay": task.scheduledDay ?? 0,
            "isCompleted": task.isCompleted
        ]
        
        let response: TaskResponse = try await makeRequest("tasks/\(task.id.uuidString)", method: "PUT", body: body)
        return response.toTask()
    }
    
    func deleteTask(_ taskId: UUID) async throws {
        let _: EmptyResponse = try await makeRequest("tasks/\(taskId.uuidString)", method: "DELETE")
    }
    
    // MARK: - Расписание (Schedule)
    func getSchedule() async throws -> [Class] {
        let response: [ClassResponse] = try await makeRequest("schedule")
        return response.map { $0.toClass() }
    }
    
    func createClass(_ classItem: Class) async throws -> Class {
        let body: [String: Any] = [
            "name": classItem.name,
            "teacher": classItem.teacher,
            "classroom": classItem.classroom,
            "startTime": classItem.startTime.timeIntervalSince1970,
            "endTime": classItem.endTime.timeIntervalSince1970,
            "dayOfWeek": classItem.dayOfWeek,
            "color": classItem.color,
            "weekNumber": classItem.weekNumber
        ]
        
        let response: ClassResponse = try await makeRequest("schedule", method: "POST", body: body)
        return response.toClass()
    }
    
    func updateClass(_ classItem: Class) async throws -> Class {
        let body: [String: Any] = [
            "name": classItem.name,
            "teacher": classItem.teacher,
            "classroom": classItem.classroom,
            "startTime": classItem.startTime.timeIntervalSince1970,
            "endTime": classItem.endTime.timeIntervalSince1970,
            "dayOfWeek": classItem.dayOfWeek,
            "color": classItem.color,
            "weekNumber": classItem.weekNumber
        ]
        
        let response: ClassResponse = try await makeRequest("schedule/\(classItem.id.uuidString)", method: "PUT", body: body)
        return response.toClass()
    }
    
    func deleteClass(_ classId: UUID) async throws {
        let _: EmptyResponse = try await makeRequest("schedule/\(classId.uuidString)", method: "DELETE")
    }
    
    // MARK: - Баллы (Grades)
    func getGrades() async throws -> [SubjectGrade] {
        let response: [SubjectGradeResponse] = try await makeRequest("grades")
        return response.map { $0.toSubjectGrade() }
    }
    
    func createSubject(_ subject: SubjectGrade) async throws -> SubjectGrade {
        let body: [String: Any] = [
            "name": subject.name,
            "examType": subject.examType.rawValue,
            "bonusPoints": subject.bonusPoints
        ]
        
        let response: SubjectGradeResponse = try await makeRequest("grades", method: "POST", body: body)
        return response.toSubjectGrade()
    }
    
    func updateSubject(_ subject: SubjectGrade) async throws -> SubjectGrade {
        let body: [String: Any] = [
            "name": subject.name,
            "examType": subject.examType.rawValue,
            "bonusPoints": subject.bonusPoints
        ]
        
        let response: SubjectGradeResponse = try await makeRequest("grades/\(subject.id.uuidString)", method: "PUT", body: body)
        return response.toSubjectGrade()
    }
    
    func deleteSubject(_ subjectId: UUID) async throws {
        let _: EmptyResponse = try await makeRequest("grades/\(subjectId.uuidString)", method: "DELETE")
    }
    
    func addAssignment(subjectId: UUID, assignment: AssignmentItem) async throws -> AssignmentItem {
        let body: [String: Any] = [
            "title": assignment.title,
            "earnedPoints": assignment.earnedPoints,
            "maxPoints": assignment.maxPoints,
            "date": assignment.date.timeIntervalSince1970,
            "isBonus": assignment.isBonus,
            "isPostedToBRS": assignment.isPostedToBRS
        ]
        
        let response: AssignmentResponse = try await makeRequest("grades/\(subjectId.uuidString)/assignments", method: "POST", body: body)
        return response.toAssignment()
    }
    
    func updateAssignment(subjectId: UUID, assignment: AssignmentItem) async throws -> AssignmentItem {
        let body: [String: Any] = [
            "title": assignment.title,
            "earnedPoints": assignment.earnedPoints,
            "maxPoints": assignment.maxPoints,
            "date": assignment.date.timeIntervalSince1970,
            "isBonus": assignment.isBonus,
            "isPostedToBRS": assignment.isPostedToBRS
        ]
        
        let response: AssignmentResponse = try await makeRequest(
            "grades/\(subjectId.uuidString)/assignments/\(assignment.id.uuidString)",
            method: "PUT",
            body: body
        )
        return response.toAssignment()
    }
    
    func deleteAssignment(subjectId: UUID, assignmentId: UUID) async throws {
        let _: EmptyResponse = try await makeRequest(
            "grades/\(subjectId.uuidString)/assignments/\(assignmentId.uuidString)",
            method: "DELETE"
        )
    }
    
    // MARK: - Карточки (Flashcards)
    func getDecks() async throws -> [FlashcardDeck] {
        let response: [FlashcardDeckResponse] = try await makeRequest("flashcards/decks")
        return response.map { $0.toDeck() }
    }
    
    func createDeck(_ deck: FlashcardDeck) async throws -> FlashcardDeck {
        let body: [String: Any] = [
            "name": deck.name,
            "subject": deck.subject
        ]
        
        let response: FlashcardDeckResponse = try await makeRequest("flashcards/decks", method: "POST", body: body)
        return response.toDeck()
    }
    
    func updateDeck(_ deck: FlashcardDeck) async throws -> FlashcardDeck {
        let body: [String: Any] = [
            "name": deck.name,
            "subject": deck.subject
        ]
        
        let response: FlashcardDeckResponse = try await makeRequest(
            "flashcards/decks/\(deck.id.uuidString)",
            method: "PUT",
            body: body
        )
        return response.toDeck()
    }
    
    func deleteDeck(_ deckId: UUID) async throws {
        let _: EmptyResponse = try await makeRequest("flashcards/decks/\(deckId.uuidString)", method: "DELETE")
    }
    
    func addCard(to deckId: UUID, card: Flashcard) async throws -> Flashcard {
        let body: [String: Any] = [
            "question": card.question,
            "answer": card.answer,
            "subject": card.subject
        ]
        
        let response: FlashcardResponse = try await makeRequest(
            "flashcards/decks/\(deckId.uuidString)/cards",
            method: "POST",
            body: body
        )
        return response.toCard()
    }
    
    func updateCard(deckId: UUID, card: Flashcard) async throws -> Flashcard {
        let body: [String: Any] = [
            "question": card.question,
            "answer": card.answer,
            "subject": card.subject
        ]
        
        let response: FlashcardResponse = try await makeRequest(
            "flashcards/decks/\(deckId.uuidString)/cards/\(card.id.uuidString)",
            method: "PUT",
            body: body
        )
        return response.toCard()
    }
    
    func deleteCard(deckId: UUID, cardId: UUID) async throws {
        let _: EmptyResponse = try await makeRequest(
            "flashcards/decks/\(deckId.uuidString)/cards/\(cardId.uuidString)",
            method: "DELETE"
        )
    }
}

// MARK: - Response Models
struct LoginResponse: Codable {
    let id: Int
    let username: String
    let email: String
    let token: String
}

struct EmptyResponse: Codable {}

// Task Response
struct TaskResponse: Codable {
    let id: String
    let title: String
    let description: String
    let creationDate: TimeInterval
    let deadline: TimeInterval?
    let isReminder: Bool
    let priority: Int
    let isCompleted: Bool
    let scheduledDay: Int?
    
    func toTask() -> Task {
        return Task(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            description: description,
            creationDate: Date(timeIntervalSince1970: creationDate),
            deadline: deadline.map { Date(timeIntervalSince1970: $0) },
            isReminder: isReminder,
            priority: priority,
            isCompleted: isCompleted,
            scheduledDay: scheduledDay,
            attachments: []
        )
    }
}

// Class Response
struct ClassResponse: Codable {
    let id: String
    let name: String
    let teacher: String
    let classroom: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let dayOfWeek: Int
    let color: String
    let weekNumber: Int
    
    func toClass() -> Class {
        return Class(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            teacher: teacher,
            classroom: classroom,
            startTime: Date(timeIntervalSince1970: startTime),
            endTime: Date(timeIntervalSince1970: endTime),
            dayOfWeek: dayOfWeek,
            color: color,
            weekNumber: weekNumber
        )
    }
}

// SubjectGrade Response
struct SubjectGradeResponse: Codable {
    let id: String
    let name: String
    let examType: String
    let assignments: [AssignmentResponse]
    let bonusPoints: Int
    
    func toSubjectGrade() -> SubjectGrade {
        let examType = ExamType(rawValue: examType) ?? .exam
        return SubjectGrade(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            examType: examType,
            assignments: assignments.map { $0.toAssignment() },
            bonusPoints: bonusPoints
        )
    }
}

struct AssignmentResponse: Codable {
    let id: String
    let title: String
    let earnedPoints: Int
    let maxPoints: Int
    let date: TimeInterval
    let isBonus: Bool
    let isPostedToBRS: Bool
    
    func toAssignment() -> AssignmentItem {
        return AssignmentItem(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            earnedPoints: earnedPoints,
            maxPoints: maxPoints,
            date: Date(timeIntervalSince1970: date),
            isBonus: isBonus,
            isPostedToBRS: isPostedToBRS
        )
    }
}

// Flashcard Responses
struct FlashcardDeckResponse: Codable {
    let id: String
    let name: String
    let subject: String
    let cards: [FlashcardResponse]
    let createdAt: TimeInterval
    
    func toDeck() -> FlashcardDeck {
        return FlashcardDeck(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            subject: subject,
            cards: cards.map { $0.toCard() }
        )
    }
}

struct FlashcardResponse: Codable {
    let id: String
    let question: String
    let answer: String
    let subject: String
    
    func toCard() -> Flashcard {
        return Flashcard(
            id: UUID(uuidString: id) ?? UUID(),
            question: question,
            answer: answer,
            subject: subject
        )
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case invalidCredentials
    case networkError
    case serverError(statusCode: Int)
}

import Foundation

struct Flashcard: Identifiable, Codable {
    let id: UUID
    var question: String
    var answer: String
    var subject: String
    
    init(id: UUID = UUID(),
         question: String,
         answer: String,
         subject: String = "Общее") {
        self.id = id
        self.question = question
        self.answer = answer
        self.subject = subject
    }
}

struct FlashcardDeck: Identifiable, Codable {
    let id: UUID
    var name: String
    var subject: String
    var cards: [Flashcard]
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, subject: String, cards: [Flashcard] = []) {
        self.id = id
        self.name = name
        self.subject = subject
        self.cards = cards
        self.createdAt = Date()
    }
}

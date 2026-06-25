import Foundation
import SwiftUI

class FlashcardManager: ObservableObject {
    @Published var decks: [FlashcardDeck] = []
    @Published var currentDeck: FlashcardDeck?
    @Published var currentCardIndex = 0
    @Published var isFlipped = false
    @Published var mistakesDeck: FlashcardDeck?
    
    private let user: User
    private let decksFileURL: URL
    private let mistakesDeckFileURL: URL
    
    init(user: User) {
        self.user = user
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.decksFileURL = directory.appendingPathComponent("flashcards_\(user.email).json")
        self.mistakesDeckFileURL = directory.appendingPathComponent("mistakes_\(user.email).json")
        loadDecks()
        loadMistakesDeck()
    }
    
    func loadDecks() {
        guard FileManager.default.fileExists(atPath: decksFileURL.path) else {
            decks = []
            return
        }
        
        do {
            let data = try Data(contentsOf: decksFileURL)
            decks = try JSONDecoder().decode([FlashcardDeck].self, from: data)
        } catch {
            print("Ошибка загрузки карточек: \(error)")
            decks = []
        }
    }
    
    func loadMistakesDeck() {
        guard FileManager.default.fileExists(atPath: mistakesDeckFileURL.path) else {
            mistakesDeck = FlashcardDeck(name: "❌ Ошибки", subject: "Требуют повторения", cards: [])
            return
        }
        
        do {
            let data = try Data(contentsOf: mistakesDeckFileURL)
            mistakesDeck = try JSONDecoder().decode(FlashcardDeck.self, from: data)
        } catch {
            print("Ошибка загрузки колоды ошибок: \(error)")
            mistakesDeck = FlashcardDeck(name: "❌ Ошибки", subject: "Требуют повторения", cards: [])
        }
    }
    
    func saveMistakesDeck() {
        guard let mistakesDeck = mistakesDeck else { return }
        do {
            let data = try JSONEncoder().encode(mistakesDeck)
            try data.write(to: mistakesDeckFileURL)
        } catch {
            print("Ошибка сохранения колоды ошибок: \(error)")
        }
    }
    
    func saveDecks() {
        do {
            let data = try JSONEncoder().encode(decks)
            try data.write(to: decksFileURL)
        } catch {
            print("Ошибка сохранения карточек: \(error)")
        }
    }
    
    func addToMistakes(card: Flashcard, from deckId: UUID) {
        guard var mistakes = mistakesDeck else {
            mistakesDeck = FlashcardDeck(name: "❌ Ошибки", subject: "Требуют повторения", cards: [card])
            saveMistakesDeck()
            return
        }
        
        if !mistakes.cards.contains(where: { $0.id == card.id }) {
            mistakes.cards.append(card)
            mistakesDeck = mistakes
            saveMistakesDeck()
            print("📝 Карточка добавлена в ошибки: \(card.question)")
        }
    }

    func removeFromMistakes(cardId: UUID) {
        guard var mistakes = mistakesDeck else { return }
        let originalCount = mistakes.cards.count
        mistakes.cards.removeAll(where: { $0.id == cardId })
        
        if mistakes.cards.count < originalCount {
            mistakesDeck = mistakes
            saveMistakesDeck()
            print("✅ Карточка удалена из ошибок")
        }
    }
    
    func isInMistakes(cardId: UUID) -> Bool {
        return mistakesDeck?.cards.contains(where: { $0.id == cardId }) ?? false
    }
    
    func addDeck(name: String, subject: String) {
        let newDeck = FlashcardDeck(name: name, subject: subject)
        decks.append(newDeck)
        saveDecks()
    }
    
    func updateDeck(deckId: UUID, newName: String, newSubject: String) {
        if let index = decks.firstIndex(where: { $0.id == deckId }) {
            decks[index].name = newName
            decks[index].subject = newSubject
            saveDecks()
        }
    }
    
    func addCard(to deckId: UUID, card: Flashcard) {
        if let index = decks.firstIndex(where: { $0.id == deckId }) {
            decks[index].cards.append(card)
            saveDecks()
            if currentDeck?.id == deckId {
                currentDeck = decks[index]
            }
        }
    }
    
    func updateCard(in deckId: UUID, cardId: UUID, newQuestion: String, newAnswer: String) {
        if let deckIndex = decks.firstIndex(where: { $0.id == deckId }),
           let cardIndex = decks[deckIndex].cards.firstIndex(where: { $0.id == cardId }) {
            decks[deckIndex].cards[cardIndex].question = newQuestion
            decks[deckIndex].cards[cardIndex].answer = newAnswer
            saveDecks()
            
            if currentDeck?.id == deckId {
                currentDeck = decks[deckIndex]
            }
            
            if var mistakes = mistakesDeck,
               let mistakeIndex = mistakes.cards.firstIndex(where: { $0.id == cardId }) {
                mistakes.cards[mistakeIndex].question = newQuestion
                mistakes.cards[mistakeIndex].answer = newAnswer
                mistakesDeck = mistakes
                saveMistakesDeck()
            }
        }
    }
    
    func deleteCard(from deckId: UUID, cardId: UUID) {
        if let deckIndex = decks.firstIndex(where: { $0.id == deckId }) {
            decks[deckIndex].cards.removeAll(where: { $0.id == cardId })
            saveDecks()
            
            if currentDeck?.id == deckId {
                currentDeck = decks[deckIndex]
            }
        }
        removeFromMistakes(cardId: cardId)
    }
    
    func deleteDeck(at offsets: IndexSet) {
        decks.remove(atOffsets: offsets)
        saveDecks()
    }
}

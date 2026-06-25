import SwiftUI

struct FlashcardView: View {
    let user: User
    @StateObject private var flashcardManager: FlashcardManager
    @State private var showingCreateDeck = false
    @State private var newDeckName = ""
    @State private var newDeckSubject = ""
    @State private var editingDeck: FlashcardDeck?
    @State private var editDeckName = ""
    @State private var editDeckSubject = ""
    @State private var selectedDeck: FlashcardDeck?
    
    init(user: User) {
        self.user = user
        _flashcardManager = StateObject(wrappedValue: FlashcardManager(user: user))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                if flashcardManager.decks.isEmpty && (flashcardManager.mistakesDeck?.cards.isEmpty ?? true) {
                    emptyStateView
                } else {
                    decksListView
                }
            }
            .navigationTitle("Флэш-карточки 📇")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateDeck = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateDeck) {
                createDeckView
            }
            .sheet(item: $editingDeck) { deck in
                editDeckView(deck: deck)
            }
            .sheet(item: $selectedDeck) { deck in
                DeckDetailView(deck: deck, manager: flashcardManager)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.fill.badge.plus")
                .font(.system(size: 70))
                .foregroundColor(.purple)
            
            Text("Нет ни одной темы")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Создайте свою первую тему")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            
            Button(action: { showingCreateDeck = true }) {
                Text("Создать тему")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .purple],
                                     startPoint: .leading,
                                     endPoint: .trailing)
                    )
                    .cornerRadius(15)
            }
            .padding(.top, 20)
        }
    }
    
    private var decksListView: some View {
        List {
            Section(header: Text("ТРЕБУЮТ ПОВТОРЕНИЯ")) {
                if let mistakesDeck = flashcardManager.mistakesDeck, !mistakesDeck.cards.isEmpty {
                    Button(action: {
                        selectedDeck = mistakesDeck
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(mistakesDeck.name)
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(mistakesDeck.subject)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("\(mistakesDeck.cards.count) карточек")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("❌ Ошибки")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Здесь появятся карточки, на которые вы ответили неверно")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("МОИ ТЕМЫ")) {
                ForEach(flashcardManager.decks) { deck in
                    HStack {
                        Button(action: {
                            selectedDeck = deck
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(deck.name)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Text(deck.subject)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("\(deck.cards.count) карточек")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            editDeckName = deck.name
                            editDeckSubject = deck.subject
                            editingDeck = deck
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            if let index = flashcardManager.decks.firstIndex(where: { $0.id == deck.id }) {
                                flashcardManager.deleteDeck(at: IndexSet(integer: index))
                            }
                        }) {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .onDelete(perform: flashcardManager.deleteDeck)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func editDeckView(deck: FlashcardDeck) -> some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о теме")) {
                    TextField("Название темы", text: $editDeckName)
                    TextField("Описание", text: $editDeckSubject)
                }
            }
            .navigationTitle("Редактирование темы")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        editingDeck = nil
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        flashcardManager.updateDeck(deckId: deck.id,
                                                    newName: editDeckName,
                                                    newSubject: editDeckSubject)
                        editingDeck = nil
                    }
                    .disabled(editDeckName.isEmpty || editDeckSubject.isEmpty)
                }
            }
        }
    }
    
    private var createDeckView: some View {
        NavigationView {
            Form {
                TextField("Название темы", text: $newDeckName)
                TextField("Описание", text: $newDeckSubject)
            }
            .navigationTitle("Новая тема")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        showingCreateDeck = false
                        resetDeckFields()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Создать") {
                        flashcardManager.addDeck(name: newDeckName, subject: newDeckSubject)
                        showingCreateDeck = false
                        resetDeckFields()
                    }
                    .disabled(newDeckName.isEmpty || newDeckSubject.isEmpty)
                }
            }
        }
    }
    
    private func resetDeckFields() {
        newDeckName = ""
        newDeckSubject = ""
    }
}

// MARK: - Детальный вид темы
struct DeckDetailView: View {
    let deck: FlashcardDeck
    @ObservedObject var manager: FlashcardManager
    @State private var showingStudy = false
    @State private var showingAddCard = false
    @State private var newQuestion = ""
    @State private var newAnswer = ""
    @State private var editingCard: Flashcard?
    @State private var showingEditCard = false
    @State private var editQuestion = ""
    @State private var editAnswer = ""
    
    var currentDeck: FlashcardDeck? {
        if deck.name == "❌ Ошибки" {
            return manager.mistakesDeck
        }
        return manager.decks.first(where: { $0.id == deck.id })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    Spacer().frame(height: 30)
                    
                    if let deck = currentDeck, deck.cards.isEmpty {
                        emptyCardsView
                    } else if let deck = currentDeck {
                        List {
                            ForEach(deck.cards) { card in
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(card.question)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text(card.answer)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        editQuestion = card.question
                                        editAnswer = card.answer
                                        editingCard = card
                                        showingEditCard = true
                                    }) {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        if let deck = currentDeck {
                                            manager.deleteCard(from: deck.id, cardId: card.id)
                                            if deck.name == "❌ Ошибки" {
                                                manager.loadMistakesDeck()
                                            }
                                        }
                                    }) {
                                        Image(systemName: "trash.circle")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .listStyle(.plain)
                    } else {
                        emptyCardsView
                    }
                    
                    studyButton
                }
                .navigationTitle(deck.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if deck.name != "❌ Ошибки" {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showingAddCard = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingAddCard) {
                    addCardView
                }
                .sheet(isPresented: $showingEditCard) {
                    editCardView
                }
                .fullScreenCover(isPresented: $showingStudy) {
                    if let deck = currentDeck {
                        StudyView(deck: deck, manager: manager, isMistakesDeck: deck.name == "❌ Ошибки", isPresented: $showingStudy)
                    }
                }
            }
        }
        .onAppear {
            if deck.name == "❌ Ошибки" {
                manager.loadMistakesDeck()
            }
        }
    }
    
    private var emptyCardsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("По этой теме пока нет карточек")
                .foregroundColor(.gray)
            if deck.name != "❌ Ошибки" {
                Button("Создать карточку") {
                    showingAddCard = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Ошибочные карточки появятся здесь после неправильных ответов")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var studyButton: some View {
        Button(action: {
            if let deck = currentDeck {
                showingStudy = true
            }
        }) {
            Text("Начать изучение 📚")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.green, .blue],
                                 startPoint: .leading,
                                 endPoint: .trailing)
                )
                .cornerRadius(15)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
        .disabled(currentDeck?.cards.isEmpty ?? true)
    }
    
    private var addCardView: some View {
        NavigationView {
            Form {
                Section(header: Text("Вопрос")) {
                    TextEditor(text: $newQuestion)
                        .frame(minHeight: 80)
                }
                
                Section(header: Text("Ответ")) {
                    TextEditor(text: $newAnswer)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Новая карточка")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        showingAddCard = false
                        newQuestion = ""
                        newAnswer = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if !newQuestion.isEmpty && !newAnswer.isEmpty {
                            let newCard = Flashcard(question: newQuestion,
                                                   answer: newAnswer,
                                                   subject: deck.subject)
                            manager.addCard(to: deck.id, card: newCard)
                            showingAddCard = false
                            newQuestion = ""
                            newAnswer = ""
                            
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }
                    .disabled(newQuestion.isEmpty || newAnswer.isEmpty)
                }
            }
        }
    }
    
    private var editCardView: some View {
        NavigationView {
            Form {
                Section(header: Text("Вопрос")) {
                    TextEditor(text: $editQuestion)
                        .frame(minHeight: 80)
                }
                
                Section(header: Text("Ответ")) {
                    TextEditor(text: $editAnswer)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Редактирование карточки")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        showingEditCard = false
                        editingCard = nil
                        editQuestion = ""
                        editAnswer = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if let card = editingCard, let deck = currentDeck {
                            manager.updateCard(in: deck.id,
                                             cardId: card.id,
                                             newQuestion: editQuestion,
                                             newAnswer: editAnswer)
                        }
                        showingEditCard = false
                        editingCard = nil
                        editQuestion = ""
                        editAnswer = ""
                    }
                    .disabled(editQuestion.isEmpty || editAnswer.isEmpty)
                }
            }
        }
    }
}

// MARK: - Режим изучения (с поддержкой темы ошибок)
struct StudyView: View {
    let deck: FlashcardDeck
    let isMistakesDeck: Bool
    @Binding var isPresented: Bool
    @ObservedObject var manager: FlashcardManager
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var correctAnswers = 0
    @State private var incorrectAnswers = 0
    @State private var showResult = false
    @State private var currentCards: [Flashcard] = []
    @State private var mistakesThisSession: Set<UUID> = []
    
    init(deck: FlashcardDeck, manager: FlashcardManager, isMistakesDeck: Bool = false, isPresented: Binding<Bool>) {
        self.deck = deck
        self.manager = manager
        self.isMistakesDeck = isMistakesDeck
        self._isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                if currentIndex >= currentCards.count && !showResult {
                    Color.clear
                        .onAppear {
                            if !isMistakesDeck {
                                for cardId in mistakesThisSession {
                                    if let card = currentCards.first(where: { $0.id == cardId }) {
                                        manager.addToMistakes(card: card, from: deck.id)
                                    }
                                }
                            }
                            showResult = true
                        }
                } else if showResult {
                    resultView
                } else {
                    VStack(spacing: 30) {
                        HStack {
                            Text("\(currentIndex + 1) / \(currentCards.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            HStack(spacing: 15) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("\(correctAnswers)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text("\(incorrectAnswers)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Button(action: {
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Выйти")
                                }
                                .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        let card = currentCards[currentIndex]
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .shadow(radius: 10)
                            
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(colors: [.blue, .purple],
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                            
                            Text(isFlipped ? card.answer : card.question)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .padding()
                                .foregroundColor(.black)
                            
                            if !isFlipped {
                                VStack {
                                    Spacer()
                                    Text("👆 нажмите для ответа")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 20)
                                }
                            }
                        }
                        .frame(height: 400)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isFlipped.toggle()
                            }
                        }
                        
                        Spacer()
                        
                        if isFlipped {
                            VStack(spacing: 20) {
                                Text("Как вы ответили?")
                                    .font(.headline)
                                
                                HStack(spacing: 30) {
                                    Button(action: {
                                        incorrectAnswers += 1
                                        if !isMistakesDeck {
                                            mistakesThisSession.insert(card.id)
                                        } else {
                                            print("Остается в ошибках")
                                        }
                                        moveToNextCard()
                                    }) {
                                        VStack {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 50))
                                            Text("Неверно")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.red)
                                    }
                                    
                                    Button(action: {
                                        correctAnswers += 1
                                        if isMistakesDeck {
                                            // В теме ошибок ответили верно - удаляем карточку
                                            manager.removeFromMistakes(cardId: card.id)
                                        }
                                        moveToNextCard()
                                    }) {
                                        VStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 50))
                                            Text("Верно")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 10)
                            .padding(.bottom, 30)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isMistakesDeck ? "❌ Ошибки" : deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            if isMistakesDeck {
                manager.loadMistakesDeck()
                currentCards = manager.mistakesDeck?.cards ?? []
            } else {
                currentCards = deck.cards
            }
            mistakesThisSession.removeAll()
        }
    }
    
    private func moveToNextCard() {
        withAnimation {
            currentIndex += 1
            isFlipped = false
        }
    }
    
    private var resultView: some View {
        VStack(spacing: 25) {
            let percentage = Double(correctAnswers) / Double(currentCards.count) * 100
            
            if percentage >= 80 {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
            } else if percentage >= 50 {
                Image(systemName: "hand.thumbsup.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
            }
            
            if percentage >= 80 {
                Text("Отлично! 🎉")
                    .font(.largeTitle)
                    .bold()
            } else if percentage >= 50 {
                Text("Неплохо! 👍")
                    .font(.largeTitle)
                    .bold()
            } else {
                Text("Есть над чем работать 💪")
                    .font(.largeTitle)
                    .bold()
            }
            
            VStack(spacing: 15) {
                HStack {
                    Text("Правильно:")
                        .font(.headline)
                    Text("\(correctAnswers)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    Text("/ \(currentCards.count)")
                        .font(.headline)
                }
                
                HStack {
                    Text("Неправильно:")
                        .font(.headline)
                    Text("\(incorrectAnswers)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.red)
                    Text("/ \(currentCards.count)")
                        .font(.headline)
                }
                
                Divider()
                
                Text("Результат: \(Int(percentage))%")
                    .font(.title3)
                    .bold()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            
            Text(resultComment(percentage: percentage))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                Button(action: {
                    currentIndex = 0
                    correctAnswers = 0
                    incorrectAnswers = 0
                    isFlipped = false
                    showResult = false
                    // Сбрасываем ошибки сессии
                    mistakesThisSession.removeAll()
                }) {
                    Text("Пройти заново 🔄")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.orange, .red],
                                         startPoint: .leading,
                                         endPoint: .trailing)
                        )
                        .cornerRadius(15)
                }
                
                Button(action: {
                    isPresented = false
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshFlashcards"), object: nil)
                }) {
                    Text("Вернуться к теме")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.blue, .purple],
                                         startPoint: .leading,
                                         endPoint: .trailing)
                        )
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
    }
    
    private func resultComment(percentage: Double) -> String {
        switch percentage {
        case 90...100:
            return "✨ Превосходный результат! Вы отлично знаете материал. Так держать!"
        case 75..<90:
            return "🌟 Хороший результат! Почти всё правильно. Повторите ошибочные карточки и будет идеально!"
        case 60..<75:
            return "📚 Неплохо, но есть над чем поработать. Попробуйте пройти карточки ещё раз!"
        case 40..<60:
            return "💪 Результат средний. Вам стоит уделить больше времени повторению материала!"
        default:
            return "🎯 Не отчаивайтесь! Сложные темы требуют времени. Продолжайте практиковаться, и результат обязательно улучшится!"
        }
    }
}

import Foundation
import SwiftUI

enum ExamType: String, CaseIterable, Codable {
    case exam = "Экзамен"
    case differentiatedPass = "Диф. зачёт"
    case pass = "Зачёт"
    
    var icon: String {
        switch self {
        case .exam: return "book.closed.fill"
        case .differentiatedPass: return "checkmark.seal.fill"
        case .pass: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .exam: return .red
        case .differentiatedPass: return .orange
        case .pass: return .green
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .exam: return 0
        case .differentiatedPass: return 1
        case .pass: return 2
        }
    }
}

// MARK: - Модель работы
struct AssignmentItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var earnedPoints: Int
    var maxPoints: Int
    var date: Date
    var isBonus: Bool
    var isPostedToBRS: Bool
    
    init(id: UUID = UUID(), title: String, earnedPoints: Int, maxPoints: Int, date: Date = Date(), isBonus: Bool = false, isPostedToBRS: Bool = false) {
        self.id = id
        self.title = title
        self.earnedPoints = earnedPoints
        self.maxPoints = maxPoints
        self.date = date
        self.isBonus = isBonus
        self.isPostedToBRS = isPostedToBRS
    }
}

// MARK: - Модель предмета с баллами
struct SubjectGrade: Identifiable, Codable {
    let id: UUID
    var name: String
    var examType: ExamType
    var assignments: [AssignmentItem]
    var bonusPoints: Int
    
    init(id: UUID = UUID(), name: String, examType: ExamType = .exam, assignments: [AssignmentItem] = [], bonusPoints: Int = 0) {
        self.id = id
        self.name = name
        self.examType = examType
        self.assignments = assignments
        self.bonusPoints = min(max(bonusPoints, 0), 10)
    }
    
    var totalEarnedPoints: Int {
        return assignments.reduce(0) { $0 + $1.earnedPoints }
    }
    
    var totalMaxPoints: Int {
        return assignments.reduce(0) { $0 + $1.maxPoints }
    }
    
    var remainingPointsLimit: Int {
        return max(0, 100 - totalEarnedPoints)
    }
    
    var totalWithBonus: Int {
        return min(totalEarnedPoints + bonusPoints, 110)
    }
}

// MARK: - Менеджер баллов с синхронизацией
class GradesManager: ObservableObject {
    @Published var subjects: [SubjectGrade] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSyncing = false
    
    private let user: User
    private let gradesFileURL: URL
    private var syncTask: _Concurrency.Task<Void, Never>?
    
    init(user: User) {
        self.user = user
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.gradesFileURL = directory.appendingPathComponent("grades_\(user.email).json")
        loadGrades()
        syncWithServer()
    }
    
    
    func loadGrades() {
        if FileManager.default.fileExists(atPath: gradesFileURL.path) {
            do {
                let data = try Data(contentsOf: gradesFileURL)
                subjects = try JSONDecoder().decode([SubjectGrade].self, from: data)
                print("✅ Загружено \(subjects.count) предметов локально")
            } catch {
                print("❌ Ошибка загрузки баллов: \(error)")
                subjects = []
            }
        } else {
            subjects = []
        }
    }
    
    func saveGrades() {
        do {
            let data = try JSONEncoder().encode(subjects)
            try data.write(to: gradesFileURL)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            print("✅ Сохранено \(subjects.count) предметов локально")
        } catch {
            print("❌ Ошибка сохранения баллов: \(error)")
        }
    }
    
    // MARK: - Синхронизация с сервером
    
    func syncWithServer() {
        syncTask?.cancel()
        
        syncTask = _Concurrency.Task { [weak self] in  // ← Используем _Concurrency.Task
            await self?.performSync()
        }
    }
    
    @MainActor
    private func performSync() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        isLoading = true
        errorMessage = nil
        
        do {
            let serverSubjects = try await APIManager.shared.getGrades()
            self.subjects = serverSubjects
            self.saveGrades()
            print("✅ Синхронизация успешна: \(serverSubjects.count) предметов")
        } catch {
            print("❌ Ошибка синхронизации: \(error)")
            errorMessage = "Не удалось синхронизировать с сервером. Данные сохранены локально."
            
            if subjects.isEmpty {
                loadGrades()
            }
        }
        
        isSyncing = false
        isLoading = false
    }
    
    // MARK: - CRUD операции с синхронизацией
    
    func addSubject(name: String, examType: ExamType) {
        let newSubject = SubjectGrade(name: name, examType: examType)
        subjects.append(newSubject)
        saveGrades()
        
        _Concurrency.Task { [weak self] in
            guard let self = self else { return }
            do {
                let _ = try await APIManager.shared.createSubject(newSubject)
                print("✅ Предмет '\(name)' создан на сервере")
            } catch {
                print("❌ Ошибка создания предмета на сервере: \(error)")
                await MainActor.run {
                    self.errorMessage = "Предмет сохранен локально, но не синхронизирован с сервером"
                }
            }
        }
    }
    
    func deleteSubject(at offsets: IndexSet) {
        let deletedSubjects = offsets.map { subjects[$0] }
        subjects.remove(atOffsets: offsets)
        saveGrades()
        
        for subject in deletedSubjects {
            _Concurrency.Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await APIManager.shared.deleteSubject(subject.id)
                    print("✅ Предмет '\(subject.name)' удален с сервера")
                } catch {
                    print("❌ Ошибка удаления предмета с сервера: \(error)")
                }
            }
        }
    }
    
    func canAddAssignment(to subjectId: UUID, earnedPoints: Int, maxPoints: Int) -> Bool {
        guard let subject = subjects.first(where: { $0.id == subjectId }) else { return false }
        
        guard maxPoints <= 100 else { return false }
        guard earnedPoints <= maxPoints else { return false }
        guard maxPoints <= subject.remainingPointsLimit else { return false }
        guard earnedPoints <= subject.remainingPointsLimit else { return false }
        
        return true
    }
    
    func addAssignment(to subjectId: UUID, title: String, earnedPoints: Int, maxPoints: Int, date: Date, isBonus: Bool, isPostedToBRS: Bool) {
        guard canAddAssignment(to: subjectId, earnedPoints: earnedPoints, maxPoints: maxPoints) else { return }
        
        guard let index = subjects.firstIndex(where: { $0.id == subjectId }) else { return }
        
        let newAssignment = AssignmentItem(
            title: title,
            earnedPoints: earnedPoints,
            maxPoints: maxPoints,
            date: date,
            isBonus: isBonus,
            isPostedToBRS: isPostedToBRS
        )
        
        subjects[index].assignments.append(newAssignment)
        saveGrades()
        
        _Concurrency.Task { [weak self] in
            guard let self = self else { return }
            do {
                let _ = try await APIManager.shared.addAssignment(subjectId: subjectId, assignment: newAssignment)
                print("✅ Работа '\(title)' добавлена на сервере")
            } catch {
                print("❌ Ошибка добавления работы на сервер: \(error)")
                await MainActor.run {
                    self.errorMessage = "Работа сохранена локально, но не синхронизирована с сервером"
                }
            }
        }
    }
    
    func updateAssignment(subjectId: UUID, assignmentId: UUID, newTitle: String, newEarnedPoints: Int, newMaxPoints: Int, newDate: Date, newIsPostedToBRS: Bool) {
        guard newEarnedPoints <= newMaxPoints else { return }
        guard newMaxPoints <= 100 else { return }
        
        if let subjectIndex = subjects.firstIndex(where: { $0.id == subjectId }),
           let assignmentIndex = subjects[subjectIndex].assignments.firstIndex(where: { $0.id == assignmentId }) {
            
            var updatedAssignment = subjects[subjectIndex].assignments[assignmentIndex]
            updatedAssignment.title = newTitle
            updatedAssignment.earnedPoints = newEarnedPoints
            updatedAssignment.maxPoints = newMaxPoints
            updatedAssignment.date = newDate
            updatedAssignment.isPostedToBRS = newIsPostedToBRS
            
            subjects[subjectIndex].assignments[assignmentIndex] = updatedAssignment
            saveGrades()
            
            _Concurrency.Task { [weak self] in
                guard let self = self else { return }
                do {
                    let _ = try await APIManager.shared.updateAssignment(subjectId: subjectId, assignment: updatedAssignment)
                    print("✅ Работа '\(newTitle)' обновлена на сервере")
                } catch {
                    print("❌ Ошибка обновления работы на сервере: \(error)")
                    await MainActor.run {
                        self.errorMessage = "Изменения сохранены локально, но не синхронизированы с сервером"
                    }
                }
            }
        }
    }
    
    func deleteAssignment(from subjectId: UUID, at offsets: IndexSet) {
        if let index = subjects.firstIndex(where: { $0.id == subjectId }) {
            let deletedAssignments = offsets.map { subjects[index].assignments[$0] }
            subjects[index].assignments.remove(atOffsets: offsets)
            saveGrades()
            
            for assignment in deletedAssignments {
                _Concurrency.Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        try await APIManager.shared.deleteAssignment(subjectId: subjectId, assignmentId: assignment.id)
                        print("✅ Работа '\(assignment.title)' удалена с сервера")
                    } catch {
                        print("❌ Ошибка удаления работы с сервера: \(error)")
                    }
                }
            }
        }
    }
    
    func updateBonusPoints(subjectId: UUID, bonusPoints: Int) {
        if let index = subjects.firstIndex(where: { $0.id == subjectId }) {
            let newBonus = min(max(bonusPoints, 0), 10)
            subjects[index].bonusPoints = newBonus
            saveGrades()
            
            _Concurrency.Task { [weak self] in
                guard let self = self else { return }
                do {
                    let _ = try await APIManager.shared.updateSubject(subjects[index])
                    print("✅ Бонусные баллы обновлены на сервере")
                } catch {
                    print("❌ Ошибка обновления бонусных баллов на сервере: \(error)")
                }
            }
        }
    }
    
    func updateSubjectName(subjectId: UUID, newName: String) {
        if let index = subjects.firstIndex(where: { $0.id == subjectId }) {
            subjects[index].name = newName
            saveGrades()
            
            _Concurrency.Task { [weak self] in  // ← Используем _Concurrency.Task
                guard let self = self else { return }
                do {
                    let _ = try await APIManager.shared.updateSubject(subjects[index])
                    print("✅ Название предмета обновлено на сервере")
                } catch {
                    print("❌ Ошибка обновления названия на сервере: \(error)")
                }
            }
        }
    }
    
    func updateExamType(subjectId: UUID, examType: ExamType) {
        if let index = subjects.firstIndex(where: { $0.id == subjectId }) {
            subjects[index].examType = examType
            saveGrades()
            
            _Concurrency.Task { [weak self] in  
                guard let self = self else { return }
                do {
                    let _ = try await APIManager.shared.updateSubject(subjects[index])
                    print("✅ Тип аттестации обновлен на сервере")
                } catch {
                    print("❌ Ошибка обновления типа аттестации на сервере: \(error)")
                }
            }
        }
    }
    
    func forceSync() {
        syncWithServer()
    }
}

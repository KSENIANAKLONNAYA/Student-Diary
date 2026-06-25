import Foundation
import SwiftUI

// MARK: - Модель достижения
struct Achievement: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
    var colorName: String
    var requiredCount: Int
    var currentCount: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    
    init(id: UUID = UUID(), title: String, description: String, icon: String, colorName: String = "gold", requiredCount: Int, currentCount: Int = 0, isUnlocked: Bool = false, unlockedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.colorName = colorName
        self.requiredCount = requiredCount
        self.currentCount = currentCount
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
}

// MARK: - Менеджер достижений
class AchievementsManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var showUnlockAnimation = false
    @Published var lastUnlockedAchievement: Achievement?
    
    private let user: User
    private let achievementsFileURL: URL
    
    init(user: User) {
        self.user = user
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.achievementsFileURL = directory.appendingPathComponent("achievements_\(user.email).json")
        loadAchievements()
    }
    
    func loadAchievements() {
        if FileManager.default.fileExists(atPath: achievementsFileURL.path) {
            do {
                let data = try Data(contentsOf: achievementsFileURL)
                achievements = try JSONDecoder().decode([Achievement].self, from: data)
                print("Загружено достижений: \(achievements.filter { $0.isUnlocked }.count)")
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            } catch {
                print("Ошибка загрузки достижений: \(error)")
                createDefaultAchievements()
            }
        } else {
            createDefaultAchievements()
        }
    }
    
    private func createDefaultAchievements() {
        achievements = [
            Achievement(title: "Первые шаги", description: "Выполните первую задачу", icon: "figure.walk", colorName: "teal", requiredCount: 1),
            Achievement(title: "Пятерка", description: "Выполните 5 задач", icon: "5.circle.fill", colorName: "cyan", requiredCount: 5),
            Achievement(title: "Десятка", description: "Выполните 10 задач", icon: "10.circle.fill", colorName: "mint", requiredCount: 10),
            Achievement(title: "Старатель", description: "Выполните 25 задач", icon: "hammer.fill", colorName: "brown", requiredCount: 25),
            Achievement(title: "Мастер", description: "Выполните 50 задач", icon: "crown.fill", colorName: "gold", requiredCount: 50),
            Achievement(title: "Легенда", description: "Выполните 100 задач", icon: "star.circle.fill", colorName: "gold", requiredCount: 100),
            Achievement(title: "7 дней подряд", description: "Выполняйте задачи 7 дней подряд", icon: "flame.fill", colorName: "orange", requiredCount: 7),
            Achievement(title: "Месяц продуктивности", description: "Выполняйте задачи 30 дней подряд", icon: "calendar.circle.fill", colorName: "purple", requiredCount: 30),
            Achievement(title: "Ранняя пташка", description: "Выполните задачу до 9:00", icon: "sunrise.fill", colorName: "yellow", requiredCount: 1),
            Achievement(title: "Совушка", description: "Выполните задачу после 23:00", icon: "moon.stars.fill", colorName: "indigo", requiredCount: 1)
        ]
        saveAchievements()
    }
    
    func saveAchievements() {
        do {
            let data = try JSONEncoder().encode(achievements)
            try data.write(to: achievementsFileURL)
            print("Сохранено достижений: \(achievements.filter { $0.isUnlocked }.count)")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            print("Ошибка сохранения достижений: \(error)")
        }
    }
    
    func checkAchievements(totalCompleted: Int, streakDays: Int, isEarlyBird: Bool, isNightOwl: Bool) {
        var newlyUnlocked: [Achievement] = []
        
        for i in 0..<achievements.count {
            var achievement = achievements[i]
            if !achievement.isUnlocked {
                var shouldUnlock = false
                
                switch achievement.title {
                case "Первые шаги":
                    if totalCompleted >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "Пятерка":
                    if totalCompleted >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "Десятка":
                    if totalCompleted >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "Старатель":
                    if totalCompleted >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "Мастер":
                    if totalCompleted >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "Легенда":
                    if totalCompleted >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "7 дней подряд":
                    if streakDays >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "Месяц продуктивности":
                    if streakDays >= achievement.requiredCount {
                        shouldUnlock = true
                    }
                case "Ранняя пташка":
                    if isEarlyBird {
                        achievement.currentCount = 1
                        if achievement.currentCount >= achievement.requiredCount {
                            shouldUnlock = true
                        }
                    }
                case "Совушка":
                    if isNightOwl {
                        achievement.currentCount = 1
                        if achievement.currentCount >= achievement.requiredCount {
                            shouldUnlock = true
                        }
                    }
                default:
                    break
                }
                
                if shouldUnlock {
                    achievement.isUnlocked = true
                    achievement.unlockedDate = Date()
                    newlyUnlocked.append(achievement)
                }
                
                achievements[i] = achievement
            }
        }
        
        saveAchievements()
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        if let lastUnlocked = newlyUnlocked.last {
            lastUnlockedAchievement = lastUnlocked
            showUnlockAnimation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showUnlockAnimation = false
            }
        }
    }
    
    func getProgress(for achievement: Achievement) -> Double {
        guard !achievement.isUnlocked else { return 1.0 }
        return Double(achievement.currentCount) / Double(achievement.requiredCount)
    }
    
    func getColor(for colorName: String) -> Color {
        switch colorName {
        case "teal": return Color.teal
        case "cyan": return Color.cyan
        case "mint": return Color.mint
        case "brown": return Color.brown
        case "gold": return Color(red: 1.0, green: 0.84, blue: 0.0)
        case "orange": return Color.orange
        case "purple": return Color.purple
        case "yellow": return Color.yellow
        case "indigo": return Color.indigo
        case "pink": return Color.pink
        case "green": return Color.green
        case "red": return Color.red
        case "blue": return Color.blue
        default: return Color.blue
        }
    }
    
    func resetStreak() {
        for i in 0..<achievements.count {
            if achievements[i].title == "7 дней подряд" || achievements[i].title == "Месяц продуктивности" {
                if !achievements[i].isUnlocked {
                    achievements[i].currentCount = 0
                }
            }
        }
        saveAchievements()
    }
}

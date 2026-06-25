import SwiftUI

struct AchievementsView: View {
    @ObservedObject var achievementsManager: AchievementsManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.95, green: 0.95, blue: 1.0),
                                            Color(red: 1.0, green: 0.95, blue: 1.0)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("Достижения")
                            .font(.largeTitle)
                            .bold()
                        
                        let unlockedCount = achievementsManager.achievements.filter { $0.isUnlocked }.count
                        Text("\(unlockedCount) / \(achievementsManager.achievements.count) получено")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Прогресс-бар общего прогресса
                    let unlockedCount = achievementsManager.achievements.filter { $0.isUnlocked }.count
                    let progress = Double(unlockedCount) / Double(achievementsManager.achievements.count)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Общий прогресс")
                            .font(.headline)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: geometry.size.width, height: 12)
                                    .cornerRadius(6)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(colors: [.blue, .purple],
                                                     startPoint: .leading,
                                                     endPoint: .trailing)
                                    )
                                    .frame(width: geometry.size.width * progress, height: 12)
                                    .cornerRadius(6)
                                    .animation(.easeInOut, value: progress)
                            }
                        }
                        .frame(height: 12)
                        
                        Text("\(Int(progress * 100))% завершено")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Список достижений
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(achievementsManager.achievements) { achievement in
                            AchievementCard(achievement: achievement, manager: achievementsManager)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            achievementsManager.objectWillChange.send()
        }
        .onReceive(achievementsManager.$achievements) { _ in
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let manager: AchievementsManager
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? manager.getColor(for: achievement.colorName).opacity(0.2) : Color.gray.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(achievement.isUnlocked ? manager.getColor(for: achievement.colorName) : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 32))
                    .foregroundColor(achievement.isUnlocked ? manager.getColor(for: achievement.colorName) : .gray)
                    .scaleEffect(isAnimating && achievement.isUnlocked ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
            }
            
            Text(achievement.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(achievement.isUnlocked ? .primary : .gray)
            
            Text(achievement.description)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            if !achievement.isUnlocked {
                ProgressView(value: manager.getProgress(for: achievement))
                    .tint(manager.getColor(for: achievement.colorName))
                    .padding(.horizontal)
            }
            
            if achievement.isUnlocked, let date = achievement.unlockedDate {
                Text("Получено \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 5)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.8)
        .onAppear {
            if achievement.isUnlocked {
                isAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            }
        }
        .id(achievement.id)
    }
}

struct UnlockAnimationView: View {
    let achievement: Achievement
    let manager: AchievementsManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    manager.showUnlockAnimation = false
                }
            
            VStack(spacing: 20) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .scaleEffect(1.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: true)
                
                Text("НОВОЕ ДОСТИЖЕНИЕ!")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .fill(manager.getColor(for: achievement.colorName).opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 45))
                        .foregroundColor(manager.getColor(for: achievement.colorName))
                }
                
                Text(achievement.title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("+\(achievement.requiredCount) XP")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(.top, 10)
                
                Button(action: {
                    manager.showUnlockAnimation = false
                }) {
                    Text("Продолжить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.purple.opacity(0.95))
                    .shadow(radius: 20)
            )
            .padding(40)
        }
    }
}

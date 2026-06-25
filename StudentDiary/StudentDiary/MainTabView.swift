import SwiftUI

struct MainTabView: View {
    let user: User
    @EnvironmentObject var userManager: UserManager
    @StateObject private var achievementsManager: AchievementsManager
    
    init(user: User) {
        self.user = user
        _achievementsManager = StateObject(wrappedValue: AchievementsManager(user: user))
    }
    
    var body: some View {
        ZStack {
            TabView {
                ScheduleView(user: user)
                    .tabItem {
                        Label("Расписание", systemImage: "calendar")
                    }
                
                StudentDiaryView(user: user)
                    .environmentObject(achievementsManager)
                    .tabItem {
                        Label("Задачи", systemImage: "checklist")
                    }
                
                FlashcardView(user: user)
                    .tabItem {
                        Label("Карточки", systemImage: "rectangle.stack.fill")
                    }
                
                GradesView(user: user)
                    .tabItem {
                        Label("Баллы", systemImage: "chart.bar.fill")
                    }
                
                AchievementsView(achievementsManager: achievementsManager)
                    .tabItem {
                        Label("Достижения", systemImage: "trophy.fill")
                    }
            }
            .accentColor(.purple)
            
            // Кнопка выхода
                        VStack {
                            HStack {
                                Button(action: {
                                    userManager.logout()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.headline)
                                        
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .shadow(color: .gray.opacity(0.3), radius: 4)
                                    )
                                }
                                .padding(.leading, 16)
                                .padding(.top, 1)
                                
                                Spacer()
                            }
                            Spacer()
                        }
                        
                        // Приветственное окно
                        if userManager.showWelcomeMessage {
                            WelcomeOverlayView(username: userManager.welcomeUserName)
                                .transition(.opacity)
                                .zIndex(1)
                        }
                    }
                }
            }

struct WelcomeOverlayView: View {
    let username: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10)
                    
                    Text(username.prefix(1).uppercased())
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Добро пожаловать!")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(username)
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.purple.opacity(0.9))
                    .shadow(radius: 20)
            )
        }
    }
}

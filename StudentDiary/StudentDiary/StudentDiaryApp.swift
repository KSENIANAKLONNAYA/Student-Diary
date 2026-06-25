import SwiftUI

// MARK: - AppDelegate для обработки уведомлений
class NotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct StudentDiaryApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) var appDelegate
    @StateObject private var userManager = UserManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userManager.currentUser != nil {
                    MainTabView(user: userManager.currentUser!)
                        .environmentObject(userManager)
                } else {
                    ContentView()
                        .environmentObject(userManager)
                }
            }
            .animation(.default, value: userManager.currentUser)
        }
    }
}

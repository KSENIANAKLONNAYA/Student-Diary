// UserManager.swift
import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()
    private let usersFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("users.json")
    
    @Published var currentUser: User?
    @Published var shouldClearFields = false
    @Published var showWelcomeMessage = false
    @Published var welcomeUserName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        loadLocalUser()
    }
    
    private func loadLocalUser() {
        guard FileManager.default.fileExists(atPath: usersFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: usersFileURL)
            let users = try JSONDecoder().decode([User].self, from: data)
            self.currentUser = users.first
        } catch {
            print("Failed to load users: \(error)")
        }
    }
    
    private func saveLocalUser(_ user: User?) {
        guard let user = user else {
            try? FileManager.default.removeItem(at: usersFileURL)
            return
        }
        do {
            let data = try JSONEncoder().encode([user])
            try data.write(to: usersFileURL, options: .atomic)
        } catch {
            print("Error saving user: \(error)")
        }
    }
    
    func getTasksFileURL(for user: User) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("tasks_\(user.email).json")
    }
    
    func getCompletedTasksFileURL(for user: User) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("completed_tasks_\(user.email).json")
    }
    
    // MARK: - Регистрация через сервер
    func registerUser(username: String, email: String, password: String) async throws -> User {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await APIManager.shared.register(username: username, email: email, password: password)
            
            await MainActor.run {
                self.currentUser = user
                self.saveLocalUser(user)
                self.isLoading = false
                self.welcomeUserName = user.username
                self.showWelcomeMessage = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showWelcomeMessage = false
                }
            }
            
            return user
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Вход через сервер 
    func loginUser(email: String, password: String) async throws -> User {
        isLoading = true
        errorMessage = nil
        
        do {
            let (user, token) = try await APIManager.shared.login(email: email, password: password)
            APIManager.shared.setAuthToken(token)
            
            await MainActor.run {
                self.currentUser = user
                self.saveLocalUser(user)
                self.isLoading = false
                self.welcomeUserName = user.username
                self.showWelcomeMessage = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showWelcomeMessage = false
                }
            }
            
            return user
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func logout() {
        APIManager.shared.clearAuthToken()
        currentUser = nil
        saveLocalUser(nil)
        shouldClearFields = true
        welcomeUserName = ""
    }
}

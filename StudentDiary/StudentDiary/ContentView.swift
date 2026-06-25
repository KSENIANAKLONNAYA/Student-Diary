import SwiftUI

struct ContentView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var animateGradient = false
    
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.6, blue: 1.0),
                        Color(red: 0.7, green: 0.5, blue: 1.0),
                        Color(red: 0.9, green: 0.4, blue: 0.8)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                Color.white.opacity(0.08)
                    .ignoresSafeArea()
                
                if userManager.showWelcomeMessage {
                    WelcomeMessageView()
                        .transition(.opacity)
                        .zIndex(1)
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 110, height: 110)
                                    .blur(radius: 5)
                                
                                Circle()
                                    .fill(.white.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "book.closed.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.2), radius: 10)
                            
                            Text("Student Diary")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Твой умный помощник в учёбе")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 25) {
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isLoginMode = true
                                        errorMessage = ""
                                    }
                                }) {
                                    Text("Вход")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(isLoginMode ? Color.white : Color.clear)
                                                .shadow(color: .black.opacity(isLoginMode ? 0.1 : 0), radius: 5)
                                        )
                                        .foregroundColor(isLoginMode ? .purple : .white)
                                }
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        isLoginMode = false
                                        errorMessage = ""
                                    }
                                }) {
                                    Text("Регистрация")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(!isLoginMode ? Color.white : Color.clear)
                                                .shadow(color: .black.opacity(!isLoginMode ? 0.1 : 0), radius: 5)
                                        )
                                        .foregroundColor(!isLoginMode ? .purple : .white)
                                }
                            }
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                            
                            VStack(spacing: 20) {
                                if !isLoginMode {
                                    ModernTextField(
                                        icon: "person.fill",
                                        placeholder: "Имя пользователя",
                                        text: $username,
                                        isSecure: false
                                    )
                                }
                                
                                ModernTextField(
                                    icon: "envelope.fill",
                                    placeholder: "Email",
                                    text: $email,
                                    isSecure: false,
                                    keyboardType: .emailAddress
                                )
                                
                                ModernTextField(
                                    icon: "lock.fill",
                                    placeholder: "Пароль",
                                    text: $password,
                                    isSecure: true
                                )
                            }
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.9))
                                    )
                                    .transition(.opacity)
                            }
                            
                            Button(action: {
                                if isLoginMode {
                                    performLogin()
                                } else {
                                    performRegistration()
                                }
                            }) {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(
                                            LinearGradient(
                                                colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(15)
                                } else {
                                    Text(isLoginMode ? "Войти" : "Создать аккаунт")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.9)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.purple)
                                        .cornerRadius(15)
                                        .shadow(color: .white.opacity(0.3), radius: 10)
                                }
                            }
                            .disabled(shouldDisableButton)
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 20)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(.purple)
        .onChange(of: userManager.shouldClearFields) { shouldClear in
            if shouldClear {
                resetForm()
                userManager.shouldClearFields = false
            }
        }
    }
    
    private var shouldDisableButton: Bool {
        isProcessing || (isLoginMode ? (email.isEmpty || password.isEmpty) : (username.isEmpty || email.isEmpty || password.isEmpty))
    }
    
    
    private func performRegistration() {
        errorMessage = ""
        isProcessing = true
        
        guard validateRegistrationFields() else {
            isProcessing = false
            return
        }
        
        _Concurrency.Task {
            do {
                let user = try await userManager.registerUser(username: username, email: email, password: password)
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func performLogin() {
        errorMessage = ""
        isProcessing = true
        
        guard validateLoginFields() else {
            isProcessing = false
            return
        }
        
        _Concurrency.Task {
            do {
                let user = try await userManager.loginUser(email: email, password: password)
                await MainActor.run {
                    isProcessing = false 
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Неверный email или пароль"
                }
            }
        }
    }
    
    private func validateRegistrationFields() -> Bool {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните все поля"
            return false
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Введите корректный email"
            return false
        }
        
        guard password.count >= 4 else {
            errorMessage = "Пароль должен содержать минимум 4 символа"
            return false
        }
        
        return true
    }
    
    private func validateLoginFields() -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните все поля"
            return false
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Введите корректный email"
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func resetForm() {
        email = ""
        password = ""
        username = ""
        errorMessage = ""
        isLoginMode = true
    }
}

// MARK: - Современное текстовое поле
struct ModernTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(isFocused ? .white : .white.opacity(0.6))
                .frame(width: 20)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.6)))
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.6)))
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(isFocused ? 0.2 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isFocused ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct WelcomeMessageView: View {
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
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                Text("Добро пожаловать!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Text("Рады видеть вас в Student Diary")
                    .foregroundColor(.white.opacity(0.9))
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserManager.shared)
    }
}

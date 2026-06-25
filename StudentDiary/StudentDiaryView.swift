import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

struct User: Codable, Equatable {
    let username: String
    let email: String
    let password: String
}

struct Attachment: Identifiable, Codable {
    let id: UUID
    var fileName: String
    var fileData: Data
    var fileType: String
    var thumbnailData: Data?
    
    init(id: UUID = UUID(), fileName: String, fileData: Data, fileType: String, thumbnailData: Data? = nil) {
        self.id = id
        self.fileName = fileName
        self.fileData = fileData
        self.fileType = fileType
        self.thumbnailData = thumbnailData
    }
    
    var image: UIImage? {
        guard fileType == "image", let image = UIImage(data: fileData) else { return nil }
        return image
    }

    var thumbnail: UIImage? {
        if let thumbnailData = thumbnailData {
            return UIImage(data: thumbnailData)
        }
        return image
    }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    let creationDate: Date
    var deadline: Date?
    var isReminder: Bool
    var priority: Int
    var isCompleted: Bool
    var scheduledDay: Int?
    var attachments: [Attachment]
    
    init(id: UUID = UUID(), title: String, description: String, creationDate: Date = Date(), deadline: Date? = nil, isReminder: Bool = false, priority: Int = 0, isCompleted: Bool = false, scheduledDay: Int? = nil, attachments: [Attachment] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.creationDate = creationDate
        self.deadline = deadline
        self.isReminder = isReminder
        self.priority = priority
        self.isCompleted = isCompleted
        self.scheduledDay = scheduledDay
        self.attachments = attachments
    }
}

extension Task {
    static let weekdaysRussian = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
    
    var scheduledDayName: String? {
        guard let day = scheduledDay, day >= 1 && day <= 7 else { return nil }
        return Task.weekdaysRussian[day - 1]
    }
    
    static func getCurrentWeekday() -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1 ? 7 : weekday - 1
    }
    
    static func getDayName(_ day: Int) -> String {
        let names = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
        return names[day - 1]
    }
}

// MARK: - Image Picker для выбора фото
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Document Picker для выбора файлов
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileData: Data?
    @Binding var selectedFileName: String?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .plainText, .presentation, .spreadsheet])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                parent.selectedFileData = data
                parent.selectedFileName = url.lastPathComponent
            } catch {
                print("Ошибка загрузки файла: \(error)")
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentPickerDidCancel(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct StudentDiaryView: View {
    let user: User
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var achievementsManager: AchievementsManager
    @State private var tasks: [Task] = []
    @State private var completedTasks: [Task] = []
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var isReminder = false
    @State private var deadlineDate = Date()
    @State private var selectedPriority = 0
    @State private var selectedTab = 0
    @State private var selectedDay: Int? = nil
    @State private var editingTask: Task? = nil
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var newAttachmentImage: UIImage?
    @State private var newAttachmentFileData: Data?
    @State private var newAttachmentFileName: String?
    
    var todayTasks: [Task] {
        let today = Task.getCurrentWeekday()
        return tasks.filter { !$0.isCompleted && $0.scheduledDay == today }
    }
    
    var tomorrowTasks: [Task] {
        let tomorrow = Task.getCurrentWeekday() + 1
        let tomorrowDay = tomorrow > 7 ? 1 : tomorrow
        return tasks.filter { !$0.isCompleted && $0.scheduledDay == tomorrowDay }
    }
    
    var thisWeekTasks: [Task] {
        let today = Task.getCurrentWeekday()
        let tomorrow = today + 1 > 7 ? 1 : today + 1
        return tasks.filter { task in
            guard !task.isCompleted, let day = task.scheduledDay else { return false }
            return day != today && day != tomorrow
        }
    }
    
    var unscheduledTasks: [Task] {
        tasks.filter { !$0.isCompleted && $0.scheduledDay == nil }
    }
    
    private var activeTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.95, green: 0.95, blue: 1.0),
                                                Color(red: 1.0, green: 0.95, blue: 1.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Picker("", selection: $selectedTab) {
                        Text("Активные").tag(0)
                        Text("Выполненные").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if selectedTab == 0 {
                        if activeTasks.isEmpty {
                            emptyStateView
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    if !todayTasks.isEmpty {
                                        taskSection(title: "СЕГОДНЯ", tasks: todayTasks, icon: "sun.max.fill", color: .orange)
                                    }
                                    
                                    if !tomorrowTasks.isEmpty {
                                        taskSection(title: "ЗАВТРА", tasks: tomorrowTasks, icon: "clock.fill", color: .blue)
                                    }
                                    
                                    if !thisWeekTasks.isEmpty {
                                        taskSection(title: "НА НЕДЕЛЕ", tasks: thisWeekTasks, icon: "calendar", color: .brown)
                                    }
                                    
                                    if !unscheduledTasks.isEmpty {
                                        taskSection(title: "ПОТОМ", tasks: unscheduledTasks, icon: "archivebox.fill", color: .gray)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    } else {
                        if completedTasks.isEmpty {
                            Text("Нет выполненных задач")
                                .foregroundColor(.gray)
                                .frame(maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(completedTasks) { task in
                                    completedTaskRowView(task: task)
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
                .navigationTitle("Мои задачи")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddTask = true
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                        }
                    }
                }
                .sheet(isPresented: $showingAddTask) {
                    addTaskView
                }
                .sheet(item: $editingTask) { task in
                    EditTaskView(task: task, onSave: { updatedTask in
                        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                            tasks[index] = updatedTask
                            saveTasks()
                        }
                    })
                }
                .onAppear {
                    loadTasks()
                    requestNotificationPermission()
                }
                
                // Анимация получения нового достижения
                if achievementsManager.showUnlockAnimation, let achievement = achievementsManager.lastUnlockedAchievement {
                    UnlockAnimationView(achievement: achievement, manager: achievementsManager)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
        }
    }
    
    private func taskSection(title: String, tasks: [Task], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            ForEach(tasks) { task in
                taskRowView(task: task)
                    .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    private func taskRowView(task: Task) -> some View {
        HStack {
            Button(action: {
                completeTask(task: task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                editingTask = task
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .strikethrough(task.isCompleted)
                        
                        if task.isReminder {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        
                        if let day = task.scheduledDay {
                            Text("• \(Task.getDayName(day))")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    Text(task.description.prefix(30) + (task.description.count > 30 ? "..." : ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .strikethrough(task.isCompleted)
                    
                    // Отображение вложений
                    if !task.attachments.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(task.attachments) { attachment in
                                Image(systemName: attachment.fileType == "image" ? "photo.fill" : "doc.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if task.isReminder, task.deadline != nil {
                        let deadline = task.deadline!
                        Text("до \(formattedRussianDate(deadline))")
                            .font(.caption2)
                            .foregroundColor(deadline < Date() ? .red : .blue)
                    }
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(action: {
                editingTask = task
            }) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks.remove(at: index)
                    saveTasks()
                }
            }) {
                Image(systemName: "trash.circle")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            if task.priority > 0 {
                Circle()
                    .fill(priorityColor(for: task.priority))
                    .frame(width: 12, height: 12)
            }
        }
    }
    private func completedTaskRowView(task: Task) -> some View {
        HStack {
            Button(action: {
                uncompleteTask(task: task)
            }) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough()
                    .foregroundColor(.gray)
                
                Text(task.description.prefix(30) + (task.description.count > 30 ? "..." : ""))
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
                    .strikethrough()
                Text("Выполнено: \(task.creationDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // Кнопка удаления
            Button(action: {
                if let index = completedTasks.firstIndex(where: { $0.id == task.id }) {
                    completedTasks.remove(at: index)
                    saveTasks()
                }
            }) {
                Image(systemName: "trash.circle")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Обработка выполнения задачи с проверкой достижений
    private func completeTask(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var completedTask = tasks[index]
            completedTask.isCompleted = true
            if completedTask.isReminder {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [completedTask.id.uuidString])
            }
            
            tasks.remove(at: index)
            completedTasks.insert(completedTask, at: 0)
            saveTasks()
            
            checkTimeBasedAchievements(for: completedTask)
            
            // Принудительно обновляем UI достижений
            DispatchQueue.main.async {
                achievementsManager.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Проверка достижений
    private func checkTimeBasedAchievements(for task: Task) {
        let hour = Calendar.current.component(.hour, from: Date())
        let isEarlyBird = hour < 9
        let isNightOwl = hour >= 23
        
        let totalCompleted = completedTasks.count
        
        // Получаем текущий стрик (дней подряд)
        let streakDays = calculateStreakDays()
        
        achievementsManager.checkAchievements(
            totalCompleted: totalCompleted,
            streakDays: streakDays,
            isEarlyBird: isEarlyBird,
            isNightOwl: isNightOwl
        )
    }
    
    // MARK: - Расчет стрика (дней подряд)
    private func calculateStreakDays() -> Int {
        let calendar = Calendar.current
        var streak = 0
        let today = Date()
        
        for dayOffset in 0...30 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let completedOnDay = completedTasks.contains { task in
                task.creationDate >= startOfDay && task.creationDate < endOfDay
            }
            
            if completedOnDay {
                streak += 1
            } else if dayOffset > 0 {
                break
            }
        }
        
        return streak
    }
    
    private func uncompleteTask(task: Task) {
        if let index = completedTasks.firstIndex(where: { $0.id == task.id }) {
            var activeTask = completedTasks[index]
            activeTask.isCompleted = false
            
            if activeTask.isReminder, activeTask.deadline != nil {
                scheduleNotification(for: activeTask)
            }
            
            completedTasks.remove(at: index)
            tasks.append(activeTask)
            saveTasks()
        }
    }
    
    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 1: return Color(red: 1.0, green: 0.6, blue: 0.6)
        case 2: return Color(red: 1.0, green: 0.4, blue: 0.4)
        case 3: return Color(red: 1.0, green: 0.2, blue: 0.2)
        default: return .clear
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("Нет активных задач")
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private var addTaskView: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название задачи", text: $newTaskTitle)
                    TextEditor(text: $newTaskDescription)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Вложения")) {
                    // Кнопки добавления
                    HStack(spacing: 20) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                Text("Фото")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showingDocumentPicker = true
                        }) {
                            VStack {
                                Image(systemName: "folder")
                                    .font(.title2)
                                Text("Файл")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    if let image = newAttachmentImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Новое фото:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(10)
                                    .clipped()
                                
                                Spacer()
                                
                                Button(action: {
                                    newAttachmentImage = nil
                                }) {
                                    Image(systemName: "trash.circle")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }
                            }
                        }
                    }
                    
                    if let fileName = newAttachmentFileName {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fileName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text("Файл будет прикреплен к задаче")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                newAttachmentFileName = nil
                                newAttachmentFileData = nil
                            }) {
                                Image(systemName: "trash.circle")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Приоритет")) {
                    Picker("Приоритет", selection: $selectedPriority) {
                        Text("Нет").tag(0)
                        Text("Низкий").tag(1)
                        Text("Средний").tag(2)
                        Text("Высокий").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("День недели")) {
                    Picker("День", selection: $selectedDay) {
                        Text("Не назначен").tag(nil as Int?)
                        ForEach(1...7, id: \.self) { day in
                            Text(Task.getDayName(day)).tag(day as Int?)
                        }
                    }
                }
                
                Section(header: Text("Напоминание")) {
                    Toggle("Сделать напоминанием", isOn: $isReminder)
                    
                    if isReminder {
                        DatePicker(
                            "Дедлайн",
                            selection: $deadlineDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        showingAddTask = false
                        resetTaskFields()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        var attachments: [Attachment] = []
                        
                        // Добавляем фото с миниатюрой
                        if let image = newAttachmentImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                            let thumbnail = image.resized(to: CGSize(width: 100, height: 100))
                            let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.6)
                            
                            let attachment = Attachment(
                                fileName: "photo_\(Date().timeIntervalSince1970).jpg",
                                fileData: imageData,
                                fileType: "image",
                                thumbnailData: thumbnailData
                            )
                            attachments.append(attachment)
                        }
                        
                        // Добавляем файл
                        if let fileData = newAttachmentFileData, let fileName = newAttachmentFileName {
                            let fileType = fileName.hasSuffix(".pdf") ? "pdf" : "document"
                            let attachment = Attachment(
                                fileName: fileName,
                                fileData: fileData,
                                fileType: fileType
                            )
                            attachments.append(attachment)
                        }
                        
                        let newTask = Task(
                            title: newTaskTitle,
                            description: newTaskDescription,
                            deadline: isReminder ? deadlineDate : nil,
                            isReminder: isReminder,
                            priority: selectedPriority,
                            scheduledDay: selectedDay,
                            attachments: attachments
                        )
                        tasks.append(newTask)
                        saveTasks()
                        if isReminder {
                            scheduleNotification(for: newTask)
                        }
                        showingAddTask = false
                        resetTaskFields()
                    }
                    .disabled(newTaskTitle.isEmpty || newTaskDescription.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $newAttachmentImage)
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(selectedFileData: $newAttachmentFileData, selectedFileName: $newAttachmentFileName)
            }
        }
    }
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Разрешение на уведомления получено")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Разрешение на уведомления отклонено: \(error?.localizedDescription ?? "неизвестная ошибка")")
            }
        }
    }
    
    private func scheduleNotification(for task: Task) {
        guard task.isReminder, let deadline = task.deadline else { return }
        
        guard deadline > Date() else {
            print("❌ Дедлайн уже прошел, уведомление не создано для задачи: \(task.title)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "📚 Напоминание: \(task.title)"
        content.body = task.description
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: deadline)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка добавления уведомления для задачи '\(task.title)': \(error.localizedDescription)")
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy HH:mm"
                print("✅ Уведомление запланировано для задачи '\(task.title)' на \(formatter.string(from: deadline))")
            }
        }
    }
    
    private func resetTaskFields() {
        newTaskTitle = ""
        newTaskDescription = ""
        isReminder = false
        deadlineDate = Date()
        selectedPriority = 0
        selectedDay = nil
        newAttachmentImage = nil
        newAttachmentFileData = nil
        newAttachmentFileName = nil
    }
    
    private func loadTasks() {
        let tasksFileURL = userManager.getTasksFileURL(for: user)
        let completedTasksFileURL = userManager.getCompletedTasksFileURL(for: user)
        
        if FileManager.default.fileExists(atPath: tasksFileURL.path) {
            do {
                let data = try Data(contentsOf: tasksFileURL)
                tasks = try JSONDecoder().decode([Task].self, from: data)
            } catch {
                print("Error loading tasks: \(error)")
                tasks = []
            }
        } else {
            tasks = []
        }
        
        if FileManager.default.fileExists(atPath: completedTasksFileURL.path) {
            do {
                let data = try Data(contentsOf: completedTasksFileURL)
                completedTasks = try JSONDecoder().decode([Task].self, from: data)
            } catch {
                print("Error loading completed tasks: \(error)")
                completedTasks = []
            }
        } else {
            completedTasks = []
        }
    }
    
    private func saveTasks() {
        let tasksFileURL = userManager.getTasksFileURL(for: user)
        let completedTasksFileURL = userManager.getCompletedTasksFileURL(for: user)
        
        do {
            let activeTasksData = try JSONEncoder().encode(tasks)
            try activeTasksData.write(to: tasksFileURL)
            let completedTasksData = try JSONEncoder().encode(completedTasks)
            try completedTasksData.write(to: completedTasksFileURL)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
    
    private func formattedRussianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy 'в' HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Отдельный вид для редактирования задачи
struct EditTaskView: View {
    @State var task: Task
    var onSave: (Task) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var newAttachmentImage: UIImage?
    @State private var newAttachmentFileData: Data?
    @State private var newAttachmentFileName: String?
    @State private var selectedAttachment: Attachment?
    @State private var showingPreview = false
    
    init(task: Task, onSave: @escaping (Task) -> Void) {
        _task = State(initialValue: task)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название задачи", text: $task.title)
                    TextEditor(text: $task.description)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Вложения (\(task.attachments.count))")) {
                    if task.attachments.isEmpty {
                        Text("Нет прикрепленных файлов")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(task.attachments) { attachment in
                                    AttachmentThumbnail(attachment: attachment) {
                                        selectedAttachment = attachment
                                        showingPreview = true
                                    } onDelete: {
                                        task.attachments.removeAll { $0.id == attachment.id }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Divider()
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                Text("Фото")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showingDocumentPicker = true
                        }) {
                            VStack {
                                Image(systemName: "folder")
                                    .font(.title2)
                                Text("Файл")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    if newAttachmentImage != nil {
                        HStack {
                            if let image = newAttachmentImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            }
                            Text("Новое фото")
                            Spacer()
                            Button(action: {
                                newAttachmentImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if let fileName = newAttachmentFileName {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(fileName)
                                .lineLimit(1)
                            Spacer()
                            Button(action: {
                                newAttachmentFileName = nil
                                newAttachmentFileData = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section(header: Text("Приоритет")) {
                    Picker("Приоритет", selection: $task.priority) {
                        Text("Нет").tag(0)
                        Text("Низкий").tag(1)
                        Text("Средний").tag(2)
                        Text("Высокий").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("День недели")) {
                    Picker("День", selection: $task.scheduledDay) {
                        Text("Не назначен").tag(nil as Int?)
                        ForEach(1...7, id: \.self) { day in
                            Text(Task.getDayName(day)).tag(day as Int?)
                        }
                    }
                }
                
                Section(header: Text("Напоминание")) {
                    Toggle("Напоминание", isOn: $task.isReminder)
                    if task.isReminder {
                        DatePicker(
                            "Дедлайн",
                            selection: Binding(
                                get: { task.deadline ?? Date() },
                                set: { task.deadline = $0 }
                            ),
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("Редактирование задачи")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if let image = newAttachmentImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                            let thumbnail = image.resized(to: CGSize(width: 100, height: 100))
                            let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.6)
                            
                            let attachment = Attachment(
                                fileName: "photo_\(Date().timeIntervalSince1970).jpg",
                                fileData: imageData,
                                fileType: "image",
                                thumbnailData: thumbnailData
                            )
                            task.attachments.append(attachment)
                        }
                        
                        if let fileData = newAttachmentFileData, let fileName = newAttachmentFileName {
                            let fileType = fileName.hasSuffix(".pdf") ? "pdf" : "document"
                            let attachment = Attachment(
                                fileName: fileName,
                                fileData: fileData,
                                fileType: fileType
                            )
                            task.attachments.append(attachment)
                        }
                        
                        onSave(task)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $newAttachmentImage)
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(selectedFileData: $newAttachmentFileData, selectedFileName: $newAttachmentFileName)
            }
            .fullScreenCover(item: $selectedAttachment) { attachment in
                AttachmentPreviewView(attachment: attachment)
            }
        }
    }
}

// MARK: - Миниатюра вложения
struct AttachmentThumbnail: View {
    let attachment: Attachment
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: onTap) {
                if attachment.fileType == "image", let thumbnail = attachment.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .cornerRadius(10)
                        .clipped()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: attachment.fileType == "pdf" ? "doc.fill" : "photo.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(attachment.fileName)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 80)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Расширение UIImage для создания миниатюры
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

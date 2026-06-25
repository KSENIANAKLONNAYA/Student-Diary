import SwiftUI

// MARK: - Тип повторения
enum RepeatType: String, CaseIterable, Codable {
    case noCycle = "Без чередования"
    case evenOdd = "Чёт/нечёт"
    case cycle3 = "Цикл 3 недели"
    case cycle4 = "Цикл 4 недели"
    
    var icon: String {
        switch self {
        case .noCycle: return "repeat.circle"
        case .evenOdd: return "arrow.left.arrow.right.circle"
        case .cycle3: return "3.circle"
        case .cycle4: return "4.circle"
        }
    }
    
    var description: String {
        switch self {
        case .noCycle: return "Одинаковое расписание каждую неделю"
        case .evenOdd: return "Две чередующиеся недели"
        case .cycle3: return "Три разных расписания, сменяющих друг друга"
        case .cycle4: return "Четыре разных расписания, сменяющих друг друга"
        }
    }
    
    var weeksCount: Int {
        switch self {
        case .noCycle: return 1
        case .evenOdd: return 2
        case .cycle3: return 3
        case .cycle4: return 4
        }
    }
    
    func getWeekName(_ offset: Int) -> String {
        switch self {
        case .noCycle:
            return "Все недели"
        case .evenOdd:
            return offset == 0 ? "Чётная" : "Нечётная"
        case .cycle3:
            return "\(offset + 1)-я"
        case .cycle4:
            return "\(offset + 1)-я"
        }
    }
}

// Модель пары
struct Class: Identifiable, Codable {
    let id: UUID
    var name: String
    var teacher: String
    var classroom: String
    var startTime: Date
    var endTime: Date
    var dayOfWeek: Int
    var color: String
    var weekNumber: Int
    
    init(id: UUID = UUID(), name: String, teacher: String = "", classroom: String = "",
         startTime: Date, endTime: Date, dayOfWeek: Int, color: String = "blue", weekNumber: Int = 0) {
        self.id = id
        self.name = name
        self.teacher = teacher
        self.classroom = classroom
        self.startTime = startTime
        self.endTime = endTime
        self.dayOfWeek = dayOfWeek
        self.color = color
        self.weekNumber = weekNumber
    }
}

struct ScheduleView: View {
    let user: User
    @State private var classes: [Class] = []
    @State private var selectedDay = getCurrentWeekday()
    @State private var showingAddClass = false
    @State private var editingClass: Class?
    @State private var newClassName = ""
    @State private var newTeacher = ""
    @State private var newClassroom = ""
    @State private var newStartTime = Date()
    @State private var newEndTime = Date().addingTimeInterval(3600)
    @State private var newDayOfWeek = getCurrentWeekday()
    @State private var selectedColor = "blue"
    
    // Состояния для управления цикличностью
    @State private var showingCycleControl = false
    @State private var currentCycleType: RepeatType = .noCycle
    @State private var selectedWeekNumber = 0
    
    private let colors: [(name: String, value: Color)] = [
        ("blue", .blue), ("green", .green), ("red", .red), ("orange", .orange),
        ("purple", .purple), ("pink", .pink), ("yellow", .yellow), ("teal", .teal)
    ]
    
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
                
                VStack(spacing: 0) {
                    // Панель управления цикличностью
                    VStack(spacing: 12) {
                        // Кнопка выбора режима
                        Button(action: {
                            showingCycleControl = true
                        }) {
                            HStack {
                                Image(systemName: currentCycleType.icon)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentCycleType.rawValue)
                                        .font(.headline)
                                    Text(currentCycleType.description)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.1), radius: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Кнопки выбора недели
                        if currentCycleType != .noCycle {
                            HStack(spacing: 8) {
                                ForEach(0..<currentCycleType.weeksCount, id: \.self) { weekNumber in
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            selectedWeekNumber = weekNumber
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Text("\(weekNumber + 1)")
                                                .font(.headline)
                                                .frame(width: 50, height: 50)
                                                .background(
                                                    selectedWeekNumber == weekNumber ?
                                                    LinearGradient(colors: [.blue, .purple],
                                                                 startPoint: .topLeading,
                                                                 endPoint: .bottomTrailing) :
                                                    LinearGradient(colors: [.gray.opacity(0.2), .gray.opacity(0.1)],
                                                                 startPoint: .topLeading,
                                                                 endPoint: .bottomTrailing)
                                                )
                                                .foregroundColor(selectedWeekNumber == weekNumber ? .white : .primary)
                                                .cornerRadius(25)
                                            
                                            Text(currentCycleType.getWeekName(weekNumber))
                                                .font(.caption2)
                                                .foregroundColor(selectedWeekNumber == weekNumber ? .blue : .gray)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.1), radius: 3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(1...7, id: \.self) { day in
                                DayButton(
                                    day: day,
                                    isSelected: selectedDay == day,
                                    weekOffset: currentCycleType == .noCycle ? 0 : selectedWeekNumber,
                                    action: { selectedDay = day }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    if getClassesForDay(selectedDay).isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Нет пар на \(getDayName(selectedDay))")
                                .foregroundColor(.gray)
                            if currentCycleType != .noCycle {
                                Text("для \(currentCycleType.getWeekName(selectedWeekNumber)) недели")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            Text("Нажмите + чтобы добавить пару")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                if currentCycleType != .noCycle {
                                    HStack {
                                        Image(systemName: "calendar.circle")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text("Расписание для \(currentCycleType.getWeekName(selectedWeekNumber)) недели")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                                
                                ForEach(getClassesForDay(selectedDay).sorted(by: { $0.startTime < $1.startTime })) { classItem in
                                    ClassCard(classItem: classItem, onEdit: {
                                        editingClass = classItem
                                        loadClassForEdit(classItem)
                                        showingAddClass = true
                                    }, onDelete: {
                                        deleteClass(classItem)
                                    })
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("📚 Расписание")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            resetClassFields()
                            showingAddClass = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddClass) {
                    addClassView
                }
                .sheet(isPresented: $showingCycleControl) {
                    CycleControlView(currentCycleType: $currentCycleType, selectedWeekNumber: $selectedWeekNumber)
                }
                .onAppear {
                    loadClasses()
                }
            }
        }
    }
    
    private func getClassesForDay(_ day: Int) -> [Class] {
        if currentCycleType == .noCycle {
            return classes.filter { $0.dayOfWeek == day && $0.weekNumber == 0 }
        } else {
            return classes.filter { $0.dayOfWeek == day && $0.weekNumber == selectedWeekNumber }
        }
    }
    
    private func loadClasses() {
        let fileURL = getClassesFileURL()
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: fileURL)
            classes = try JSONDecoder().decode([Class].self, from: data)
        } catch {
            print("Ошибка загрузки расписания: \(error)")
        }
    }
    
    private func saveClasses() {
        let fileURL = getClassesFileURL()
        do {
            let data = try JSONEncoder().encode(classes)
            try data.write(to: fileURL)
        } catch {
            print("Ошибка сохранения расписания: \(error)")
        }
    }
    
    private func getClassesFileURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("schedule_\(user.email).json")
    }
    
    private func addClass() {
        let weekNumber = currentCycleType == .noCycle ? 0 : selectedWeekNumber
        
        let newClass = Class(
            name: newClassName,
            teacher: newTeacher,
            classroom: newClassroom,
            startTime: newStartTime,
            endTime: newEndTime,
            dayOfWeek: newDayOfWeek,
            color: selectedColor,
            weekNumber: weekNumber
        )
        classes.append(newClass)
        saveClasses()
        showingAddClass = false
        resetClassFields()
    }
    
    private func updateClass() {
        guard let editing = editingClass,
              let index = classes.firstIndex(where: { $0.id == editing.id }) else { return }
        
        let weekNumber = currentCycleType == .noCycle ? 0 : selectedWeekNumber
        
        let updatedClass = Class(
            id: editing.id,
            name: newClassName,
            teacher: newTeacher,
            classroom: newClassroom,
            startTime: newStartTime,
            endTime: newEndTime,
            dayOfWeek: newDayOfWeek,
            color: selectedColor,
            weekNumber: weekNumber
        )
        classes[index] = updatedClass
        saveClasses()
        showingAddClass = false
        resetClassFields()
        editingClass = nil
    }
    
    private func deleteClass(_ classItem: Class) {
        classes.removeAll { $0.id == classItem.id }
        saveClasses()
    }
    
    private func loadClassForEdit(_ classItem: Class) {
        newClassName = classItem.name
        newTeacher = classItem.teacher
        newClassroom = classItem.classroom
        newStartTime = classItem.startTime
        newEndTime = classItem.endTime
        newDayOfWeek = classItem.dayOfWeek
        selectedColor = classItem.color
    }
    
    private func resetClassFields() {
        newClassName = ""
        newTeacher = ""
        newClassroom = ""
        newStartTime = Date()
        newEndTime = Date().addingTimeInterval(3600)
        newDayOfWeek = selectedDay
        selectedColor = "blue"
        editingClass = nil
    }
    
    private var addClassView: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о паре")) {
                    TextField("Название предмета", text: $newClassName)
                    TextField("Преподаватель", text: $newTeacher)
                    TextField("Аудитория", text: $newClassroom)
                }
                
                Section(header: Text("Время")) {
                    DatePicker("Начало", selection: $newStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("Окончание", selection: $newEndTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("День недели")) {
                    Picker("День", selection: $newDayOfWeek) {
                        ForEach(1...7, id: \.self) { day in
                            Text(getDayName(day)).tag(day)
                        }
                    }
                }
                
                if currentCycleType != .noCycle {
                    Section(header: Text("Привязка к неделе")) {
                        HStack {
                            Image(systemName: "calendar.circle")
                                .foregroundColor(.blue)
                            Text("Добавляется к \(currentCycleType.getWeekName(selectedWeekNumber)) неделе")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        Text("Вы можете переключить неделю в главном экране")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Цвет предмета")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colors, id: \.name) { color in
                                Circle()
                                    .fill(color.value)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color.name ? Color.black : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedColor = color.name
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(editingClass == nil ? "Новая пара" : "Редактирование")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        showingAddClass = false
                        resetClassFields()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingClass == nil ? "Создать" : "Сохранить") {
                        if editingClass == nil {
                            addClass()
                        } else {
                            updateClass()
                        }
                    }
                    .disabled(newClassName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Отдельное окно выбора режима цикличности
struct CycleControlView: View {
    @Binding var currentCycleType: RepeatType
    @Binding var selectedWeekNumber: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(RepeatType.allCases, id: \.self) { type in
                    Button(action: {
                        withAnimation(.spring()) {
                            currentCycleType = type
                            selectedWeekNumber = 0
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if currentCycleType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Режим цикличности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - DayButton
struct DayButton: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void
    let weekOffset: Int
    
    init(day: Int, isSelected: Bool, weekOffset: Int = 0, action: @escaping () -> Void) {
        self.day = day
        self.isSelected = isSelected
        self.weekOffset = weekOffset
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(getShortDayName(day))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(getDayDate())
                    .font(.caption2)
            }
            .frame(width: 55, height: 65)
            .background(isSelected ? Color.blue : Color.white.opacity(0.9))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 3)
        }
    }
    
    private func getShortDayName(_ day: Int) -> String {
        let names = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"]
        return names[day - 1]
    }
    
    private func getDayDate() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        let currentWeekdayIOS = calendar.component(.weekday, from: today)
        let currentWeekday = currentWeekdayIOS == 1 ? 7 : currentWeekdayIOS - 1
        
        let daysToMonday = -(currentWeekday - 1)
        let currentWeekStart = calendar.date(byAdding: .day, value: daysToMonday, to: today) ?? today
        
        let targetWeekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: currentWeekStart) ?? currentWeekStart
    
        let targetDate = calendar.date(byAdding: .day, value: day - 1, to: targetWeekStart) ?? today
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        
        let dateString = formatter.string(from: targetDate)
        
        if weekOffset == 0 && calendar.isDateInToday(targetDate) {
            return "Сегодня"
        }
        
        return dateString
    }
}

// MARK: - ClassCard
struct ClassCard: View {
    let classItem: Class
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private func getColor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .blue
        }
    }
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(getColor(classItem.color))
                .frame(width: 6)
                .cornerRadius(3)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(classItem.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label(classItem.teacher, systemImage: "person.fill")
                        .font(.caption)
                    Label(classItem.classroom, systemImage: "building.columns.fill")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                
                Text(timeString(from: classItem.startTime) + " - " + timeString(from: classItem.endTime))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash.circle")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 3)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Вспомогательные функции
func getCurrentWeekday() -> Int {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())
    return weekday == 1 ? 7 : weekday - 1
}

func getDayName(_ day: Int) -> String {
    let names = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
    return names[day - 1]
}

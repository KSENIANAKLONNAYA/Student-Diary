import SwiftUI

// MARK: - Вспомогательная функция для склонения слов
func pluralize(_ count: Int, _ forms: (one: String, few: String, many: String)) -> String {
    let mod10 = count % 10
    let mod100 = count % 100
    
    if mod100 >= 11 && mod100 <= 19 {
        return "\(count) \(forms.many)"
    }
    
    switch mod10 {
    case 1:
        return "\(count) \(forms.one)"
    case 2, 3, 4:
        return "\(count) \(forms.few)"
    default:
        return "\(count) \(forms.many)"
    }
}

// MARK: - Цветовая схема (по суммарным баллам)
func pointsColor(earned: Int, max: Int) -> Color {
    if earned >= 85 {
        return .green
    } else if earned >= 71 {
        return .yellow
    } else if earned >= 38 {
        return .orange
    } else {
        return .red
    }
}

struct GradesView: View {
    let user: User
    @StateObject private var gradesManager: GradesManager
    @State private var showingAddSubject = false
    @State private var newSubjectName = ""
    @State private var selectedSubjectForDetail: SubjectGrade?
    @State private var newExamType: ExamType = .exam
    
    init(user: User) {
        self.user = user
        _gradesManager = StateObject(wrappedValue: GradesManager(user: user))
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
                
                if gradesManager.subjects.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(gradesManager.subjects.sorted(by: { $0.examType.sortOrder < $1.examType.sortOrder })) { subject in
                            SubjectCard(
                                subject: subject,
                                manager: gradesManager,
                                onEdit: {
                                    selectedSubjectForDetail = subject
                                },
                                onDelete: {
                                    if let index = gradesManager.subjects.firstIndex(where: { $0.id == subject.id }) {
                                        gradesManager.deleteSubject(at: IndexSet(integer: index))
                                    }
                                }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Мои баллы 🎯")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        newSubjectName = ""
                        newExamType = .exam
                        showingAddSubject = true
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingAddSubject) {
                addSubjectView
            }
            .sheet(item: $selectedSubjectForDetail) { subject in
                SubjectDetailView(subject: subject, manager: gradesManager)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 70))
                .foregroundColor(.purple)
            
            Text("Нет предметов")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Добавьте предмет, чтобы начать отслеживать баллы")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            
            Button(action: {
                newSubjectName = ""
                newExamType = .exam
                showingAddSubject = true
            }) {
                Text("Добавить предмет")
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
    
    private var addSubjectView: some View {
        NavigationView {
            Form {
                TextField("Название предмета", text: $newSubjectName)
                
                Section(header: Text("Тип аттестации")) {
                    Picker("Тип", selection: $newExamType) {
                        ForEach(ExamType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Новый предмет")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        showingAddSubject = false
                        newSubjectName = ""
                        newExamType = .exam
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        if !newSubjectName.isEmpty {
                            gradesManager.addSubject(name: newSubjectName, examType: newExamType)
                            showingAddSubject = false
                            newSubjectName = ""
                            newExamType = .exam
                        }
                    }
                    .disabled(newSubjectName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Карточка предмета
    struct SubjectCard: View {
        let subject: SubjectGrade
        let manager: GradesManager
        let onEdit: () -> Void
        let onDelete: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subject.name)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Label(subject.examType.rawValue, systemImage: subject.examType.icon)
                            .font(.caption2)
                            .foregroundColor(subject.examType.color)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(pointsColor(earned: subject.totalEarnedPoints, max: 100))
                        .frame(width: 20, height: 20)
                    
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
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Итого: \(subject.totalEarnedPoints)/100")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        let bonusText = pluralize(subject.bonusPoints, (one: "бонус", few: "бонуса", many: "бонусов"))
                        Text("+\(bonusText)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    let percent = Double(subject.totalWithBonus) / 110 * 100
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: geometry.size.width, height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(pointsColor(earned: subject.totalEarnedPoints, max: 100))
                                .frame(width: geometry.size.width * percent / 100, height: 8)
                                .cornerRadius(4)
                                .animation(.easeInOut, value: subject.totalEarnedPoints)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        let assignmentsText = pluralize(subject.assignments.count, (one: "работа", few: "работы", many: "работ"))
                        Text(assignmentsText)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(Int(percent))%")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(pointsColor(earned: subject.totalEarnedPoints, max: 100))
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
    
    // MARK: - Детальный вид предмета
    struct SubjectDetailView: View {
        @ObservedObject var manager: GradesManager
        let subjectId: UUID
        @State private var subject: SubjectGrade
        @State private var localAssignments: [AssignmentItem] = []
        @State private var showingAddAssignment = false
        @State private var newTitle = ""
        @State private var newEarnedPoints = ""
        @State private var newMaxPoints = ""
        @State private var editingBonusPoints = 0
        @State private var showingBonusEditor = false
        @State private var editingAssignment: AssignmentItem?
        @State private var editTitle = ""
        @State private var editEarnedPoints = ""
        @State private var editMaxPoints = ""
        @State private var newDate = Date()
        @State private var editDate = Date()
        @State private var isEditingName = false
        @State private var editedName = ""
        @State private var editedExamType: ExamType
        @State private var newIsPostedToBRS = false
        @Environment(\.dismiss) var dismiss
        
        init(subject: SubjectGrade, manager: GradesManager) {
            self.manager = manager
            self.subjectId = subject.id
            _subject = State(initialValue: subject)
            _localAssignments = State(initialValue: subject.assignments)
            _editedExamType = State(initialValue: subject.examType)
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
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Редактируемый заголовок
                            HStack {
                                if isEditingName {
                                    TextField("Название предмета", text: $editedName)
                                        .font(.title2)
                                        .bold()
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button("Сохранить") {
                                        manager.updateSubjectName(subjectId: subjectId, newName: editedName)
                                        if let updatedSubject = manager.subjects.first(where: { $0.id == subjectId }) {
                                            subject = updatedSubject
                                            localAssignments = updatedSubject.assignments
                                        }
                                        isEditingName = false
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                } else {
                                    Text(subject.name)
                                        .font(.title2)
                                        .bold()
                                    
                                    Button(action: {
                                        editedName = subject.name
                                        isEditingName = true
                                    }) {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            statsCard
                            bonusCard
                            examTypeCard
                            
                            if localAssignments.isEmpty {
                                emptyAssignmentsView
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    let worksText = pluralize(localAssignments.count, (one: "работа", few: "работы", many: "работ"))
                                    Text("📝 Все \(worksText)")
                                        .font(.headline)
                                        .padding(.horizontal, 16)
                                    
                                    ForEach($localAssignments, id: \.id) { $assignment in
                                        AssignmentRow(
                                            assignment: assignment,
                                            onEdit: {
                                                editingAssignment = assignment
                                                editTitle = assignment.title
                                                editEarnedPoints = "\(assignment.earnedPoints)"
                                                editMaxPoints = "\(assignment.maxPoints)"
                                                editDate = assignment.date
                                            },
                                            onDelete: {
                                                if let index = localAssignments.firstIndex(where: { $0.id == assignment.id }) {
                                                    manager.deleteAssignment(from: subjectId, at: IndexSet(integer: index))
                                                    localAssignments.remove(at: index)
                                                }
                                            },
                                            onTogglePosted: {
                                                if let index = localAssignments.firstIndex(where: { $0.id == assignment.id }) {
                                                    localAssignments[index].isPostedToBRS.toggle()
                                                    let updated = localAssignments[index]
                                                    manager.updateAssignment(
                                                        subjectId: subjectId,
                                                        assignmentId: updated.id,
                                                        newTitle: updated.title,
                                                        newEarnedPoints: updated.earnedPoints,
                                                        newMaxPoints: updated.maxPoints,
                                                        newDate: updated.date,
                                                        newIsPostedToBRS: updated.isPostedToBRS
                                                    )
                                                    if let updatedSubject = manager.subjects.first(where: { $0.id == subjectId }) {
                                                        subject = updatedSubject
                                                    }
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddAssignment = true
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddAssignment) {
                addAssignmentView
            }
            .sheet(isPresented: $showingBonusEditor) {
                editBonusView
            }
            .sheet(item: $editingAssignment) { assignment in
                EditAssignmentSheet(
                    assignment: assignment,
                    subjectId: subjectId,
                    manager: manager,
                    onSave: {
                        if let updatedSubject = manager.subjects.first(where: { $0.id == subjectId }) {
                            subject = updatedSubject
                            localAssignments = updatedSubject.assignments
                        }
                    }
                )
            }
            .onReceive(manager.$subjects) { updatedSubjects in
                if let updatedSubject = updatedSubjects.first(where: { $0.id == subjectId }) {
                    subject = updatedSubject
                    localAssignments = updatedSubject.assignments
                }
            }
        }
        
        private var statsCard: some View {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    StatItem(title: "Основные баллы", value: "\(subject.totalEarnedPoints)/100", color: pointsColor(earned: subject.totalEarnedPoints, max: 100))
                    StatItem(title: "Бонус", value: "\(subject.bonusPoints)/10", color: .orange)
                    StatItem(title: "Итого", value: "\(subject.totalWithBonus)/110", color: .purple)
                }
                
                if subject.totalEarnedPoints >= 100 {
                    Text("✅ Максимум основных баллов достигнут")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                let percent = Double(subject.totalWithBonus) / 110 * 100
                Text("Общий прогресс: \(Int(percent))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            .padding(.horizontal, 16)
        }
        
        private var examTypeCard: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: subject.examType.icon)
                        .foregroundColor(subject.examType.color)
                    Text("Тип аттестации")
                        .font(.headline)
                    Spacer()
                    
                    Picker("", selection: $editedExamType) {
                        ForEach(ExamType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: editedExamType) { newValue in
                        manager.updateExamType(subjectId: subjectId, examType: newValue)
                        if let updatedSubject = manager.subjects.first(where: { $0.id == subjectId }) {
                            subject = updatedSubject
                            localAssignments = updatedSubject.assignments
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            .padding(.horizontal, 16)
        }
        
        private var bonusCard: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Бонусные баллы")
                        .font(.headline)
                    Spacer()
                    Text("\(subject.bonusPoints)/10")
                        .font(.title3)
                        .bold()
                        .foregroundColor(subject.bonusPoints == 10 ? .green : .orange)
                    
                    Button(action: {
                        editingBonusPoints = subject.bonusPoints
                        showingBonusEditor = true
                    }) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                
                let remainingBonus = 10 - subject.bonusPoints
                if remainingBonus > 0 {
                    let remainingText = pluralize(remainingBonus, (one: "бонусный балл", few: "бонусных балла", many: "бонусных баллов"))
                    Text("✨ Можно добавить ещё \(remainingText)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("✅ Максимум бонусов достигнут")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            .padding(.horizontal, 16)
        }
        
        private var editBonusView: some View {
            NavigationView {
                Form {
                    Section(header: Text("Редактирование бонусных баллов")) {
                        HStack {
                            Text("Бонусные баллы")
                            Spacer()
                            TextField("0-10", value: $editingBonusPoints, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("/ 10")
                        }
                        
                        if editingBonusPoints < 0 {
                            Text("⚠️ Бонусные баллы не могут быть отрицательными")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if editingBonusPoints > 10 {
                            Text("⚠️ Бонусные баллы не могут быть больше 10")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            let remaining = 10 - editingBonusPoints
                            if remaining > 0 {
                                let remainingText = pluralize(remaining, (one: "бонусный балл", few: "бонусных балла", many: "бонусных баллов"))
                                Text("✨ Осталось свободных: \(remainingText)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if remaining == 0 {
                                Text("✅ Максимум бонусов достигнут")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .navigationTitle("Редактирование бонусов")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Отмена") {
                            showingBonusEditor = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Сохранить") {
                            if editingBonusPoints >= 0 && editingBonusPoints <= 10 {
                                manager.updateBonusPoints(subjectId: subject.id, bonusPoints: editingBonusPoints)
                                showingBonusEditor = false
                            }
                        }
                        .disabled(editingBonusPoints < 0 || editingBonusPoints > 10)
                    }
                }
            }
        }
        
        private var emptyAssignmentsView: some View {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("Нет добавленных работ")
                    .foregroundColor(.gray)
                Text("Нажмите + чтобы добавить")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(15)
            .padding(.horizontal, 16)
        }
        
        private var addAssignmentView: some View {
            NavigationView {
                Form {
                    Section(header: Text("Информация о работе")) {
                        TextField("Название работы", text: $newTitle)
                        
                        HStack {
                            TextField("Набрано баллов", text: $newEarnedPoints)
                                .keyboardType(.numberPad)
                            Text("из")
                            TextField("Максимум баллов", text: $newMaxPoints)
                                .keyboardType(.numberPad)
                        }
                        
                        DatePicker("Дата получения", selection: $newDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                        
                        Toggle("Баллы выставлены в БРС", isOn: $newIsPostedToBRS)
                        
                        if let max = Int(newMaxPoints), max > 100 {
                            Text("⚠️ Работа не может быть больше 100 баллов")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let earned = Int(newEarnedPoints), let max = Int(newMaxPoints), earned > max {
                            Text("⚠️ Набранные баллы не могут быть больше максимальных")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let max = Int(newMaxPoints), max > subject.remainingPointsLimit {
                            Text("⚠️ Максимум баллов не может превышать \(subject.remainingPointsLimit) (осталось места)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let earned = Int(newEarnedPoints), earned > subject.remainingPointsLimit {
                            Text("⚠️ Набранные баллы не могут превышать \(subject.remainingPointsLimit) (осталось места)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Новая работа")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Отмена") {
                            showingAddAssignment = false
                            resetFields()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Сохранить") {
                            if let earned = Int(newEarnedPoints),
                               let max = Int(newMaxPoints),
                               !newTitle.isEmpty,
                               manager.canAddAssignment(to: subject.id, earnedPoints: earned, maxPoints: max) {
                                manager.addAssignment(
                                    to: subject.id,
                                    title: newTitle,
                                    earnedPoints: earned,
                                    maxPoints: max,
                                    date: newDate,
                                    isBonus: false,
                                    isPostedToBRS: newIsPostedToBRS
                                )
                                if let updatedSubject = manager.subjects.first(where: { $0.id == subject.id }) {
                                    subject = updatedSubject
                                    localAssignments = updatedSubject.assignments
                                }
                                showingAddAssignment = false
                                resetFields()
                            }
                        }
                        .disabled(newTitle.isEmpty || newEarnedPoints.isEmpty || newMaxPoints.isEmpty)
                    }
                }
            }
        }
        
        private func resetFields() {
            newTitle = ""
            newEarnedPoints = ""
            newMaxPoints = ""
            newDate = Date()
            newIsPostedToBRS = false
        }
    }
    
    // MARK: - Отдельное view для редактирования работы
    struct EditAssignmentSheet: View {
        let assignment: AssignmentItem  // ← Исправлено: Assignment → AssignmentItem
        let subjectId: UUID
        let manager: GradesManager
        let onSave: () -> Void
        
        @State private var editTitle = ""
        @State private var editEarnedPoints = ""
        @State private var editMaxPoints = ""
        @State private var editDate = Date()
        @State private var editIsPostedToBRS = false
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Информация о работе")) {
                        TextField("Название работы", text: $editTitle)
                        
                        HStack {
                            TextField("Набрано баллов", text: $editEarnedPoints)
                                .keyboardType(.numberPad)
                            Text("из")
                            TextField("Максимум баллов", text: $editMaxPoints)
                                .keyboardType(.numberPad)
                        }
                        
                        DatePicker("Дата получения", selection: $editDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                        
                        Toggle("Баллы выставлены в БРС", isOn: $editIsPostedToBRS)
                        
                        if let earned = Int(editEarnedPoints), let max = Int(editMaxPoints), earned > max {
                            Text("⚠️ Набранные баллы не могут быть больше максимальных")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if let max = Int(editMaxPoints), max > 100 {
                            Text("⚠️ Работа не может быть больше 100 баллов")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Редактирование работы")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Отмена") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Сохранить") {
                            let earned = Int(editEarnedPoints) ?? 0
                            let max = Int(editMaxPoints) ?? 0
                            
                            if !editTitle.isEmpty && earned <= max && max <= 100 {
                                manager.updateAssignment(
                                    subjectId: subjectId,
                                    assignmentId: assignment.id,
                                    newTitle: editTitle,
                                    newEarnedPoints: earned,
                                    newMaxPoints: max,
                                    newDate: editDate,
                                    newIsPostedToBRS: editIsPostedToBRS
                                )
                                onSave()
                                dismiss()
                            }
                        }
                        .disabled(
                            editTitle.isEmpty ||
                            editEarnedPoints.isEmpty ||
                            editMaxPoints.isEmpty ||
                            Int(editEarnedPoints) == nil ||
                            Int(editMaxPoints) == nil ||
                            (Int(editEarnedPoints) ?? 0) > (Int(editMaxPoints) ?? 0) ||
                            (Int(editMaxPoints) ?? 0) > 100
                        )
                    }
                }
            }
            .onAppear {
                editTitle = assignment.title
                editEarnedPoints = "\(assignment.earnedPoints)"
                editMaxPoints = "\(assignment.maxPoints)"
                editDate = assignment.date
                editIsPostedToBRS = assignment.isPostedToBRS
            }
        }
    }
    
    // MARK: - Статистика
    struct StatItem: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Строка работы
    struct AssignmentRow: View {
        let assignment: AssignmentItem  // ← Исправлено: Assignment → AssignmentItem
        let onEdit: () -> Void
        let onDelete: () -> Void
        let onTogglePosted: () -> Void
        
        var body: some View {
            HStack {
                Button(action: onTogglePosted) {
                    Image(systemName: assignment.isPostedToBRS ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(assignment.isPostedToBRS ? .green : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title)
                        .font(.headline)
                        .strikethrough(assignment.isPostedToBRS)
                        .foregroundColor(assignment.isPostedToBRS ? .gray : .primary)
                    
                    Text(assignment.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("\(assignment.earnedPoints)/\(assignment.maxPoints)")
                        .font(.caption)
                        .foregroundColor(pointsColor(earned: assignment.earnedPoints, max: assignment.maxPoints))
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
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import uuid
from datetime import datetime
import json

app = Flask(__name__)
CORS(app)  # Разрешаем запросы с iOS

# Настройка базы данных
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///student_diary.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# ==================== МОДЕЛИ ====================

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(100), nullable=False)

class Task(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, default='')
    creation_date = db.Column(db.Float, default=lambda: datetime.now().timestamp())
    deadline = db.Column(db.Float, nullable=True)
    is_reminder = db.Column(db.Boolean, default=False)
    priority = db.Column(db.Integer, default=0)
    is_completed = db.Column(db.Boolean, default=False)
    scheduled_day = db.Column(db.Integer, nullable=True)

class ClassItem(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    teacher = db.Column(db.String(100), default='')
    classroom = db.Column(db.String(100), default='')
    start_time = db.Column(db.Float, nullable=False)
    end_time = db.Column(db.Float, nullable=False)
    day_of_week = db.Column(db.Integer, nullable=False)
    color = db.Column(db.String(50), default='blue')
    week_number = db.Column(db.Integer, default=0)

class Subject(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    exam_type = db.Column(db.String(50), default='exam')
    bonus_points = db.Column(db.Integer, default=0)

class Assignment(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    subject_id = db.Column(db.String(36), db.ForeignKey('subject.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    earned_points = db.Column(db.Integer, default=0)
    max_points = db.Column(db.Integer, default=0)
    date = db.Column(db.Float, default=lambda: datetime.now().timestamp())
    is_bonus = db.Column(db.Boolean, default=False)
    is_posted_to_brs = db.Column(db.Boolean, default=False)

class FlashcardDeck(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    subject = db.Column(db.String(200), default='')
    created_at = db.Column(db.Float, default=lambda: datetime.now().timestamp())

class Flashcard(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    deck_id = db.Column(db.String(36), db.ForeignKey('flashcard_deck.id'), nullable=False)
    question = db.Column(db.Text, nullable=False)
    answer = db.Column(db.Text, nullable=False)
    subject = db.Column(db.String(200), default='')

# ==================== ЭНДПОИНТЫ ====================

@app.route('/')
def home():
    return jsonify({"message": "Student Diary API is running!"})

# ---------- АУТЕНТИФИКАЦИЯ ----------

@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    
    if User.query.filter_by(email=email).first():
        return jsonify({"error": "User already exists"}), 400
    
    user = User(username=username, email=email, password=password)
    db.session.add(user)
    db.session.commit()
    
    return jsonify({
        "id": user.id,
        "username": user.username,
        "email": user.email
    }), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    
    user = User.query.filter_by(email=email, password=password).first()
    if not user:
        return jsonify({"error": "Invalid credentials"}), 401
    
    return jsonify({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "token": f"fake-jwt-token-{user.id}"
    })

# ---------- ЗАДАЧИ ----------

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    # Для теста возвращаем пример
    return jsonify([
        {
            "id": str(uuid.uuid4()),
            "title": "Подготовиться к экзамену",
            "description": "Повторить все темы",
            "creationDate": datetime.now().timestamp(),
            "deadline": None,
            "isReminder": False,
            "priority": 2,
            "isCompleted": False,
            "scheduledDay": 3
        }
    ])

@app.route('/api/tasks', methods=['POST'])
def create_task():
    data = request.json
    return jsonify({**data, "id": str(uuid.uuid4())}), 201

@app.route('/api/tasks/<task_id>', methods=['PUT'])
def update_task(task_id):
    data = request.json
    return jsonify({**data, "id": task_id})

@app.route('/api/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    return jsonify({"message": "Task deleted"}), 200

# ---------- РАСПИСАНИЕ ----------

@app.route('/api/schedule', methods=['GET'])
def get_schedule():
    return jsonify([])

@app.route('/api/schedule', methods=['POST'])
def create_class():
    data = request.json
    return jsonify({**data, "id": str(uuid.uuid4())}), 201

@app.route('/api/schedule/<class_id>', methods=['PUT'])
def update_class(class_id):
    data = request.json
    return jsonify({**data, "id": class_id})

@app.route('/api/schedule/<class_id>', methods=['DELETE'])
def delete_class(class_id):
    return jsonify({"message": "Class deleted"}), 200

# ---------- БАЛЛЫ ----------

@app.route('/api/grades', methods=['GET'])
def get_grades():
    return jsonify([])

@app.route('/api/grades', methods=['POST'])
def create_subject():
    data = request.json
    return jsonify({**data, "id": str(uuid.uuid4())}), 201

@app.route('/api/grades/<subject_id>', methods=['PUT'])
def update_subject(subject_id):
    data = request.json
    return jsonify({**data, "id": subject_id})

@app.route('/api/grades/<subject_id>', methods=['DELETE'])
def delete_subject(subject_id):
    return jsonify({"message": "Subject deleted"}), 200

@app.route('/api/grades/<subject_id>/assignments', methods=['POST'])
def add_assignment(subject_id):
    data = request.json
    return jsonify({**data, "id": str(uuid.uuid4())}), 201

@app.route('/api/grades/<subject_id>/assignments/<assignment_id>', methods=['PUT'])
def update_assignment(subject_id, assignment_id):
    data = request.json
    return jsonify({**data, "id": assignment_id})

@app.route('/api/grades/<subject_id>/assignments/<assignment_id>', methods=['DELETE'])
def delete_assignment(subject_id, assignment_id):
    return jsonify({"message": "Assignment deleted"}), 200

# ---------- КАРТОЧКИ ----------

@app.route('/api/flashcards/decks', methods=['GET'])
def get_decks():
    return jsonify([])

@app.route('/api/flashcards/decks', methods=['POST'])
def create_deck():
    data = request.json
    return jsonify({**data, "id": str(uuid.uuid4()), "cards": []}), 201

@app.route('/api/flashcards/decks/<deck_id>', methods=['PUT'])
def update_deck(deck_id):
    data = request.json
    return jsonify({**data, "id": deck_id})

@app.route('/api/flashcards/decks/<deck_id>', methods=['DELETE'])
def delete_deck(deck_id):
    return jsonify({"message": "Deck deleted"}), 200

@app.route('/api/flashcards/decks/<deck_id>/cards', methods=['POST'])
def add_card(deck_id):
    data = request.json
    return jsonify({**data, "id": str(uuid.uuid4())}), 201

@app.route('/api/flashcards/decks/<deck_id>/cards/<card_id>', methods=['PUT'])
def update_card(deck_id, card_id):
    data = request.json
    return jsonify({**data, "id": card_id})

@app.route('/api/flashcards/decks/<deck_id>/cards/<card_id>', methods=['DELETE'])
def delete_card(deck_id, card_id):
    return jsonify({"message": "Card deleted"}), 200

# ==================== ЗАПУСК ====================

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print("✅ База данных создана!")
    print("🚀 Сервер запускается на http://localhost:8000")
    app.run(debug=True, host='0.0.0.0', port=8000)
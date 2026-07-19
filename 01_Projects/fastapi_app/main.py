"""
🚀 FastAPI — первое приложение (с Pydantic)

📍 Запуск:
    source .venv/bin/activate
    uvicorn main:app --reload

📖 Открыть: http://127.0.0.1:8000
📖 Документация: http://127.0.0.1:8000/docs
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# ─── Pydantic модели ──────────────────────────────────────


class UserCreate(BaseModel):
    """Модель для создания пользователя (POST)."""
    name: str
    age: int


class UserResponse(BaseModel):
    """Модель ответа — пользователь с ID."""
    id: int
    name: str
    age: int


# ─── In-memory база данных ────────────────────────────────
users_db: list[UserResponse] = [
    UserResponse(id=1, name="Анна", age=25),
    UserResponse(id=2, name="Борис", age=30),
    UserResponse(id=3, name="Вика", age=25),
]
next_id: int = 4


# ─── Приложение ────────────────────────────────────────────
app = FastAPI(title="Моё первое FastAPI приложение")


# ─── Роутер: корень ───────────────────────────────────────
@app.get("/")
def root():
    """GET / — приветственный эндпоинт"""
    return {"message": "Привет, FastAPI!", "status": "ok"}


# ─── Роутер: приветствие пользователя ─────────────────────
@app.get("/hello/{name}")
def hello_user(name: str):
    """
    GET /hello/{name} — персональное приветствие.

    FastAPI сам парсит name из URL и проверяет тип str.
    """
    return {
        "message": f"Привет, {name}!",
        "name_length": len(name),
    }


# ─── POST /users — создание пользователя ──────────────────
@app.post("/users", status_code=201)
def create_user(user: UserCreate) -> UserResponse:
    """
    POST /users — создать нового пользователя.

    Тело запроса (JSON):
    {
        "name": "Олег",
        "age": 28
    }
    """
    global next_id

    new_user = UserResponse(id=next_id, name=user.name, age=user.age)
    users_db.append(new_user)
    next_id += 1

    return new_user


# ─── GET /users — список пользователей ────────────────────
@app.get("/users")
def get_users(age: int | None = None) -> dict:
    """
    GET /users?age=25 — фильтрация по возрасту.

    Query-параметр age опционален (None по умолчанию).
    """
    if age is not None:
        filtered = [u for u in users_db if u.age == age]
        return {"users": filtered, "count": len(filtered)}

    return {"users": users_db, "count": len(users_db)}


# ─── GET /users/{user_id} — один пользователь ─────────────
@app.get("/users/{user_id}")
def get_user(user_id: int) -> UserResponse:
    """
    GET /users/{user_id} — получить пользователя по ID.
    """
    for user in users_db:
        if user.id == user_id:
            return user

    raise HTTPException(status_code=404, detail="User not found")


# ─── Точка входа для запуска напрямую через python ──────
if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)

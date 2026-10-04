"""
🧪 test_api.py — Авто-тест всех эндпоинтов FastAPI

Запуск (в отдельном терминале, пока сервер работает):
    cd ~/Desktop/coli-dev && .venv/bin/python 01_Projects/fastapi_app/test_api.py
"""

import urllib.request
import json
import sys

BASE_URL = "http://127.0.0.1:8000"
passed = 0
failed = 0


def check_endpoint(name: str, method: str, path: str, expected_status: int = 200, body: dict | None = None):
    global passed, failed
    url = f"{BASE_URL}{path}"
    data = json.dumps(body).encode() if body else None

    try:
        req = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={"Content-Type": "application/json"} if body else {}
        )
        with urllib.request.urlopen(req) as resp:
            status = resp.status
            body_text = resp.read().decode()
    except urllib.error.HTTPError as e:
        status = e.code
        body_text = e.read().decode()
    except Exception as e:
        print(f"  ❌ {name} — ОШИБКА: {e}")
        failed += 1
        return

    # Проверяем статус
    status_ok = "✅" if status == expected_status else f"⚠️ (ожидался {expected_status})"

    try:
        result = json.loads(body_text)
        print(f"  {status_ok} {name} — {status}")
        print(f"     Ответ: {json.dumps(result, ensure_ascii=False, indent=4)}")
    except json.JSONDecodeError:
        print(f"  {status_ok} {name} — {status} (не JSON)")
        print(f"     {body_text[:200]}")

    if status == expected_status:
        passed += 1
    else:
        failed += 1


def main():
    print("=" * 50)
    print("  🧪 ТЕСТИРОВАНИЕ FASTAPI")
    print(f"  Сервер: {BASE_URL}")
    print("=" * 50)
    print()

    # ─── 1. GET / ──────────────────────────────────────
    print("📌 1. GET / — приветствие")
    check_endpoint("GET /", "GET", "/")

    # ─── 2. GET /hello/{name} ──────────────────────────
    print("\n📌 2. GET /hello/Макс — приветствие пользователя")
    check_endpoint("GET /hello/Макс", "GET", "/hello/Макс")

    # ─── 3. GET /users — все ───────────────────────────
    print("\n📌 3. GET /users — все пользователи")
    check_endpoint("GET /users", "GET", "/users")

    # ─── 4. GET /users?age=25 — фильтр ─────────────────
    print("\n📌 4. GET /users?age=25 — фильтр по возрасту")
    check_endpoint("GET /users?age=25", "GET", "/users?age=25")

    # ─── 5. POST /users — создать пользователя ─────────
    print("\n📌 5. POST /users — создать пользователя")
    check_endpoint("POST /users (Олег)", "POST", "/users", expected_status=201, body={
        "name": "Олег",
        "age": 28
    })

    # ─── 6. GET /users/4 — проверить нового ────────────
    print("\n📌 6. GET /users/4 — новый пользователь по ID")
    check_endpoint("GET /users/4", "GET", "/users/4")

    # ─── 7. GET /users/99 — 404 ────────────────────────
    print("\n📌 7. GET /users/99 — несуществующий (404)")
    check_endpoint("GET /users/99 (404)", "GET", "/users/99", expected_status=404)

    # ─── 8. GET /users?age=30 — ещё фильтр ─────────────
    print("\n📌 8. GET /users?age=30 — фильтр (Борис)")
    check_endpoint("GET /users?age=30", "GET", "/users?age=30")

    # ─── ИТОГИ ─────────────────────────────────────────
    print("\n" + "=" * 50)
    print(f"  ✅ Пройдено: {passed}")
    print(f"  ❌ Провалено: {failed}")
    print(f"  📊 Всего: {passed + failed}")
    print("=" * 50)

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()

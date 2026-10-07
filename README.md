# ColiDev

**A native macOS learning app with bilingual courses, interactive practice, and a local AI tutor.**<br>
**Нативное учебное приложение для macOS с двуязычными курсами, интерактивной практикой и локальным ИИ-тьютором.**

ColiDev brings structured learning, a lesson-aware tutor, and local course search into one SwiftUI app backed by a Python service.<br>
ColiDev объединяет последовательное обучение, ИИ-тьютора с контекстом урока и локальный поиск по курсам в одном приложении SwiftUI с сервером на Python.

The app is in active development. Current builds are team previews, not a finished or bug-free product.<br>
Приложение активно разрабатывается. Текущие сборки предназначены для тестирования командой; это ещё не готовый продукт без ошибок.

The interface and starter materials support Russian and English. The six priority subjects are mathematics, English, physics, biology, zoology, and programming.<br>
Интерфейс и начальные учебные материалы доступны на русском и английском. Шесть приоритетных направлений: математика, английский язык, физика, биология, зоология и программирование.

## Try a macOS preview / Попробовать предварительную сборку macOS

[Download the latest unsigned preview / Скачать последнюю неподписанную сборку](https://github.com/invinby/coli-dev/releases/tag/preview-2026-10-07-measurement-lab). Choose the archive for Apple Silicon or Intel, extract it, and open `ColiDev.app`. macOS may ask you to confirm because the app is unsigned.<br>
[Скачать последнюю неподписанную сборку](https://github.com/invinby/coli-dev/releases/tag/preview-2026-10-07-measurement-lab). Выберите архив для Apple Silicon или Intel, распакуйте его и откройте `ColiDev.app`. macOS может попросить подтвердить запуск, потому что приложение не подписано.

The preview is for team testing. It is not notarized, and visual, keyboard, VoiceOver, and live-service checks on a physical Mac are still required.<br>
Эта сборка предназначена для командного тестирования. Она не нотариально заверена; на реальном Mac ещё нужно проверить интерфейс, клавиатуру, VoiceOver и работу подключённых сервисов.

## What works now / Что уже работает

- A SwiftUI client for macOS 13 and later, with Russian and English interface strings, six subject areas, lesson pages, interactive exercises, and locally saved study progress.<br>
  Клиент на SwiftUI для macOS 13 и новее: интерфейс на русском и английском, шесть предметных направлений, страницы уроков, интерактивные упражнения и локальное сохранение прогресса.
- The repository contains 47 bilingual lesson files. They form a starter collection, not complete or academically reviewed courses.<br>
  В репозитории 57 двуязычных файлов уроков. Это начальная подборка, а не полные курсы с академической проверкой.
- Courses are planned from foundations through advanced topics. Each roadmap is an outline; its presence does not mean every topic has a finished lesson.<br>
  Учебные маршруты идут от основ к углублённым темам. Каждый маршрут пока является планом: его наличие не означает, что для каждой темы уже готов урок.
- A local FastAPI backend provides the tutor, study-progress storage, service settings, and Obsidian routes. The macOS app can start its packaged backend runtime.<br>
  Локальный сервер FastAPI обслуживает тьютора, хранение прогресса, настройки сервисов и интеграцию с Obsidian. Приложение macOS умеет запускать встроенную сборку сервера.
- Auto routing has a free-only default. It can use the exact OpenRouter `openrouter/free` route when configured and local Ollama for local agent roles and fallbacks. Paid cloud routes require an explicit cost-policy setting. Provider quotas and availability are not guaranteed.<br>
  По умолчанию режим Auto использует только бесплатную маршрутизацию. При настройке он может обращаться к точному маршруту OpenRouter `openrouter/free`, а для локальных ролей и запасных ответов — к Ollama. Платные облачные маршруты требуют явного разрешения в настройках расходов. Лимиты и доступность у провайдеров приложение не гарантирует.
- The Control Center can choose separate Ollama models for draft, critic, and verifier roles. It lists installed local model IDs and accepts a model ID entered by hand. These role preferences cannot silently switch to cloud providers.<br>
  В Центре управления можно выбрать отдельные модели Ollama для черновика, критики и проверки. Он показывает установленные локальные модели и позволяет ввести идентификатор вручную. Эти настройки ролей не переключают их в облако автоматически.
- Local RAG indexes Markdown course files and text cheat sheets in SQLite. It supports lexical search and optional Ollama embeddings; search results can include file paths and line ranges. Chat retrieval is capped at four sources.<br>
  Локальный RAG индексирует учебные Markdown-файлы и текстовые шпаргалки в SQLite. Доступен обычный текстовый поиск и необязательные векторные представления через Ollama; в результатах могут быть пути к файлам и строки. В чат передаётся не более четырёх найденных источников.
- The admin tools can inspect retrieved sources and show source dates, licenses, and attribution. The backend checks a fixed list of official-source URLs while it is running. A person can preview an approved page and record a review after its content fingerprint is checked again.<br>
  Инструменты администратора позволяют просматривать найденные источники, их даты, лицензии и атрибуцию. Во время работы сервер проверяет ограниченный список URL официальных источников. Человек может открыть текст одобренной страницы и записать проверку только после повторной сверки отпечатка её содержимого.
- **Lesson content does not update or get approved automatically.** Source checks do not rewrite lessons. A recorded review is an editorial note, not proof that a whole course is current or correct. Web-grounded retrieval covers only a small, explicitly approved source set.<br>
  **Содержание уроков не обновляется и не утверждается автоматически.** Проверки источников не переписывают уроки. Запись о проверке — это заметка редактора, а не доказательство актуальности или правильности всего курса. Поиск по веб-источникам охватывает лишь небольшой явно одобренный набор материалов.
- Optional Google Search grounding is blocked by default and requires a configured Gemini key plus explicit permission for potentially paid cloud calls. It can include local course or Obsidian excerpts only after a separate choice and warning. It may use quota or incur charges.<br>
  Дополнительный поиск Google отключён по умолчанию: для него нужен ключ Gemini и явное разрешение на потенциально платные облачные запросы. Фрагменты курсов или Obsidian можно добавить только отдельным выбором после предупреждения. Такой поиск может расходовать квоту или привести к оплате.
- The physics starter includes interactive motion and measurement exercises. One 3D prototype models one-dimensional motion under constant force; it does not model general rigid-body dynamics. Other starter visual exercises are 2D.<br>
  В начальном курсе физики есть интерактивные задания по движению и измерениям. Один 3D-прототип моделирует одномерное движение под действием постоянной силы; он не моделирует динамику произвольных твёрдых тел. Остальные стартовые визуальные упражнения двумерные.
- Obsidian search and saving lesson/session notes are optional and require its loopback Local REST API. NotebookLM support exports a lesson as a local Markdown file for the learner to import; direct NotebookLM API integration and synchronization are not implemented.<br>
  Поиск в Obsidian и сохранение заметок урока или занятия доступны по желанию и требуют локального Local REST API. Для NotebookLM урок можно экспортировать в Markdown-файл и импортировать вручную; прямое подключение к API NotebookLM и синхронизация пока не реализованы.

## Still in development / Что ещё разрабатывается

Full course coverage and editorial review, automatic content updates, a complete video library, subject-specific 3D practice, broader license-reviewed source coverage, automatic editorial approval, NotebookLM synchronization, and account-based cross-device sync are not implemented. See the [project plan / план проекта](project-plan/README.md) for the detailed scope and status.<br>
Полное покрытие курсов и редакторская проверка, автоматическое обновление учебных материалов, полноценная видеотека, 3D-тренажёры по всем направлениям, расширение набора источников с проверкой лицензий, автоматическое редакторское утверждение, синхронизация с NotebookLM и аккаунтная синхронизация между устройствами ещё не реализованы. Подробный объём и статус см. в [плане проекта](project-plan/README.md).

## Run the backend / Запустить сервер

From the repository root, create an environment, install the backend dependencies, copy the sample configuration, and start the API.<br>
В корне репозитория создайте виртуальное окружение, установите зависимости сервера, скопируйте пример настроек и запустите API.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-orchestrator.txt
cp .env.example .env
python 01_Projects/orchestrator.py
```

In Windows PowerShell, create the environment with `py -3 -m venv .venv`, activate it with `\.venv\Scripts\Activate.ps1`, and copy the configuration with `Copy-Item .env.example .env`.<br>
В Windows PowerShell создайте окружение командой `py -3 -m venv .venv`, активируйте его через `\.venv\Scripts\Activate.ps1` и скопируйте настройки командой `Copy-Item .env.example .env`.

The server listens on `127.0.0.1:8000` by default. A source build from Xcode needs the backend started separately unless you package it with `macOS/ColiDev/scripts/package_backend_runtime.sh`. The CI preview bundles a PyInstaller runtime.<br>
По умолчанию сервер слушает `127.0.0.1:8000`. При сборке исходников через Xcode сервер нужно запускать отдельно, если не упаковать его скриптом `macOS/ColiDev/scripts/package_backend_runtime.sh`. В сборку из CI включён runtime PyInstaller.

## Build and check / Собрать и проверить

Open `macOS/ColiDev/ColiDev.xcodeproj` in Xcode, choose the `ColiDev` scheme, and run it. The [macOS notes / заметки по macOS](macOS/ColiDev/README.md) describe packaging the backend runtime.<br>
Откройте `macOS/ColiDev/ColiDev.xcodeproj` в Xcode, выберите схему `ColiDev` и запустите приложение. В [заметках по macOS](macOS/ColiDev/README.md) описана упаковка серверного runtime.

Run the backend checks with:<br>
Запустить проверки сервера можно так:

```bash
python -m pip install -r requirements-test.txt
python -m pytest 01_Projects -q
```

The test suite mocks provider requests. It does not spend API credits or verify live services. GitHub Actions also builds the app for Apple Silicon and Intel and checks the packaged backend; it does not replace hands-on Mac acceptance.<br>
В тестах запросы к провайдерам заменены заглушками. Проверки не расходуют API-кредиты и не подтверждают работу настоящих сервисов. GitHub Actions также собирает приложение для Apple Silicon и Intel и проверяет упакованный сервер, но не заменяет ручную проверку на Mac.

## Keys and local data / Ключи и локальные данные

On macOS, credentials saved in the Control Center are stored in Keychain; their values are not returned to the app client. The ignored `.env` file is a development fallback. Never commit real provider or Obsidian credentials.<br>
В macOS ключи, сохранённые через Центр управления, хранятся в Keychain; приложение не возвращает их значения клиенту. Игнорируемый Git файл `.env` служит запасным вариантом для разработки. Никогда не добавляйте настоящие ключи провайдеров или Obsidian в репозиторий.

Course indexes, session state, study progress, and logs use per-user system data directories. The backend binds to loopback by default and does not provide user-account authentication. Keep it local unless network access is deliberately designed and protected.<br>
Индексы курсов, состояние занятий, прогресс и журналы хранятся в системных каталогах текущего пользователя. По умолчанию сервер привязан к loopback-адресу и не использует авторизацию аккаунтов. Оставляйте его локальным, пока сетевой доступ отдельно не спроектирован и не защищён.

The global cost policy gates potentially paid model routes and Google Search on the backend. Saving credentials alone does not enable these routes.<br>
Общая политика расходов блокирует потенциально платные маршруты моделей и Google Search на стороне сервера. Одно лишь сохранение ключей эти маршруты не включает.

---

**Project repository / Репозиторий проекта:** [github.com/invinby/coli-dev](https://github.com/invinby/coli-dev)<br>
**Current preview / Текущая сборка для тестирования:** [macOS preview / сборка macOS](https://github.com/invinby/coli-dev/releases/tag/preview-2026-10-07-measurement-lab)

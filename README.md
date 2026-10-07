# ColiDev

**A native macOS learning platform with bilingual courses, interactive practice, and an AI tutor.**<br>
**Нативная учебная платформа для macOS с двуязычными курсами, интерактивной практикой и ИИ-тьютором.**

ColiDev combines structured courses, saved learning progress, subject-specific exercises, local course search, and configurable AI routes in one SwiftUI app with a local Python service.<br>
ColiDev объединяет последовательные курсы, сохранение учебного прогресса, упражнения по предметам, локальный поиск по материалам и настраиваемые маршруты ИИ в одном приложении SwiftUI с локальным сервером на Python.

**Project status: early team prototype.** The app is not a finished, signed, or bug-free release. Feature status and known limits are described below and in the project plan.<br>
**Статус проекта: ранний командный прототип.** Приложение ещё не является готовым, подписанным или полностью проверенным релизом. Статус функций и известные ограничения описаны ниже и в плане проекта.

## Preview for macOS / Предварительная сборка для macOS

[Open the latest published preview / Открыть последнюю опубликованную сборку](https://github.com/invinby/coli-dev/releases/tag/preview-2026-10-07-measurement-lab). Download the archive for Apple Silicon or Intel, extract it, and open ColiDev.app. This preview is unsigned and not notarized, so macOS may ask you to confirm that you want to open it.<br>
[Открыть последнюю опубликованную сборку](https://github.com/invinby/coli-dev/releases/tag/preview-2026-10-07-measurement-lab). Скачайте архив для Apple Silicon или Intel, распакуйте его и откройте ColiDev.app. Эта сборка не подписана и не нотариально заверена, поэтому macOS может попросить подтвердить запуск.

This is the last published release preview. New pull-request builds are separate test artifacts and are not published releases.<br>
Это последняя опубликованная предварительная сборка. Новые сборки из pull request публикуются отдельно как тестовые артефакты и не считаются релизами.

## Latest macOS test build / Последняя тестовая сборка macOS

GitHub Actions run [37700478188](https://github.com/invinby/coli-dev/actions/runs/37700478188) passed for app commit `9169ae1`: backend checks, Swift verification, Apple Silicon and Intel app builds, bundled-backend smoke checks, and course-resource checks all succeeded. The run contains `ColiDev-macos-arm64` (21,966,610 bytes) and `ColiDev-macos-x86_64` (22,872,971 bytes) test artifacts, available until 21 October 2026. Open the run page and download the artifact matching your Mac.<br>
Запуск GitHub Actions [37700478188](https://github.com/invinby/coli-dev/actions/runs/37700478188) успешно прошёл для коммита приложения `9169ae1`: backend-проверки, Swift-проверки, сборки для Apple Silicon и Intel, smoke-проверка встроенного backend и проверка ресурсов курсов. В запуске доступны тестовые архивы `ColiDev-macos-arm64` (21 966 610 байт) и `ColiDev-macos-x86_64` (22 872 971 байт) до 21 октября 2026 года. Откройте страницу запуска и скачайте архив для своего Mac.<br>

These CI artifacts are unsigned test builds, not a published release. CI verifies compilation and bundled-backend smoke checks; running the app and checking its real UI and model routes on a Mac still requires hands-on acceptance.<br>
Это неподписанные тестовые архивы CI, а не опубликованный релиз. CI проверяет сборку и smoke-проверку встроенного backend; запуск приложения и проверка реального интерфейса и маршрутов моделей на Mac всё ещё требуют ручной приёмки.

## Project profile / Профиль проекта

| English | Русский |
|---|---|
| **Platform:** native SwiftUI app for macOS 13 and later, with a local FastAPI service. | **Платформа:** нативное приложение SwiftUI для macOS 13 и новее с локальным сервером FastAPI. |
| **Languages:** Russian and English interface strings and starter learning materials. | **Языки:** русский и английский в интерфейсе и начальных учебных материалах. |
| **Priority subjects:** mathematics, English, physics, biology, zoology, and programming. | **Приоритетные направления:** математика, английский язык, физика, биология, зоология и программирование. |
| **Learning loop:** explanation, examples, practice, feedback, self-check, and saved progress. | **Цикл обучения:** объяснение, примеры, практика, обратная связь, самопроверка и сохранение прогресса. |
| **AI modes:** local Ollama and configured online providers, with a free-only default policy for automatic routing. | **Режимы ИИ:** локальная Ollama и настроенные онлайн-провайдеры; автоматическая маршрутизация по умолчанию ограничена бесплатными вариантами. |
| **Knowledge:** local course search with source-aware tutor context; approved web-source checks do not rewrite lessons automatically. | **Материалы:** локальный поиск по курсам с передачей источников тьютору; проверки одобренных веб-источников сами по себе не переписывают уроки. |
| **Product goal:** help learners move from foundations to advanced understanding across major disciplines, while keeping lesson completion separate from demonstrated mastery. | **Цель продукта:** помогать переходить от основ к углублённому пониманию разных важных дисциплин, отдельно показывая завершение уроков и подтверждённое освоение знаний. |
| **Adaptive learning:** recommend prerequisites, practice, review, or a harder next step from observed learner results; avoid one fixed template for every subject. | **Адаптивное обучение:** по результатам ученика предлагать нужные основы, практику, повторение или более сложный следующий шаг; не применять один шаблон ко всем предметам. |
| **Visual learning:** use interactive diagrams, simulations, video, or manipulable 3D when they explain a concept; describe each model’s assumptions and limits. | **Наглядное обучение:** использовать интерактивные схемы, симуляции, видео или управляемые 3D-модели, когда они помогают понять тему; указывать предпосылки и ограничения каждой модели. |
| **Learner-created curriculum:** let learners add their own subjects and topics without duplicating the built-in catalog; Biology is already a built-in subject. | **Пользовательская программа:** дать ученику возможность добавлять свои предметы и темы, не дублируя встроенный каталог; биология уже входит в стандартный список предметов. |
| **Evidence and accuracy:** prefer current official or primary sources, show attribution and review dates, and mark uncertainty instead of inventing evidence. | **Источники и точность:** отдавать предпочтение актуальным официальным или первичным источникам, показывать атрибуцию и даты проверки, а при неопределённости сообщать об этом вместо выдуманных подтверждений. |

The rows marked as product goals describe the intended direction; they are not claims that every adaptive, visual, or mastery feature is already complete.<br>
Строки с целями продукта описывают направление развития и не означают, что все функции адаптации, визуализации и оценки освоения уже готовы.

## What works in the prototype / Что работает в прототипе

- The macOS app contains six subject areas, lesson pages, interactive exercises, and locally saved study progress. The six directions are a starting catalog, not complete courses.<br>
  Приложение macOS содержит шесть направлений, страницы уроков, интерактивные упражнения и локальное сохранение прогресса. Это начальный каталог, а не шесть завершённых курсов.

- The repository contains 47 bilingual lesson files. They are a starter collection; coverage and academic review vary by subject and level.<br>
  В репозитории есть 47 двуязычных файлов уроков. Это начальная подборка; полнота и академическая проверка различаются по предметам и уровням.

- The course maps are planned from foundational material toward advanced topics. A topic listed in a roadmap does not necessarily have a finished lesson yet.<br>
  Карты курсов ведут от основ к углублённым темам. Наличие темы в плане не означает, что готовый урок уже написан.

- Lesson progress is saved locally and supports review scheduling. Course completion and actual mastery are separate product goals; the prototype does not yet provide a complete mastery model.<br>
  Прогресс уроков сохраняется локально и используется для планирования повторений. Завершение курса и реальное освоение материала — разные цели; в прототипе пока нет полной модели оценки знаний.

- The home screen counts completed lessons linked in the built-in roadmaps, rather than counting the six subject introductions. It explicitly says that subject-level mastery is not assessed yet.<br>
  Главный экран считает завершённые уроки, связанные со встроенными дорожными картами, а не шесть вводных карточек предметов. Он прямо сообщает, что общее освоение предметов пока не оценивается.

- The current draft branch adds a progress-aware Continue action: due reviews come first, then the last opened unfinished lesson, then the next lesson in the least-completed built-in subject. This is a completion-based heuristic, not mastery-based personalization.<br>
  Текущая рабочая ветка добавляет кнопку «Продолжить» с учётом прогресса: сначала предлагается просроченное повторение, затем последний открытый незавершённый урок, а после — следующий урок в наименее пройденном встроенном предмете. Это эвристика по завершённым урокам, а не персонализация по реальному освоению.

- The local backend serves the tutor, course retrieval, progress synchronization, service settings, and the loopback Obsidian bridge. The app can package and launch that backend runtime.<br>
  Локальный сервер обслуживает тьютора, поиск по курсам, синхронизацию прогресса, настройки сервисов и локальную интеграцию с Obsidian. Приложение умеет упаковывать и запускать этот сервер.

- AI routes can be configured by role. The Control Center has a separate Local models screen for Ollama availability, installed models, and local role assignments. Paid cloud routes require a separate cost-policy setting; saving an API key does not enable them by itself.<br>
  Маршруты ИИ можно настраивать отдельно для разных ролей. В Центре управления есть отдельный экран «Локальные модели» с доступностью Ollama, установленными моделями и назначениями локальных ролей. Для платных облачных маршрутов нужно отдельно разрешить расходы; одно сохранение ключа API само по себе их не включает.

- Tutor readiness distinguishes a responding local backend from a configured model route. The app does not treat internet access or an unused session allowance as proof that a model is ready.<br>
  Статус тьютора отдельно показывает, отвечает ли локальный сервер и настроен ли маршрут к модели. Наличие интернета или неиспользованной квоты сессии не считается подтверждением готовности модели.

- The local RAG index searches course Markdown and text resources. It supports lexical search and optional Ollama embeddings; tutor retrieval is limited to a small number of sources for each answer.<br>
  Локальный индекс RAG ищет по Markdown-урокам и текстовым материалам. Доступен обычный текстовый поиск и необязательные векторные представления через Ollama; для ответа тьютору передаётся ограниченное число источников.

- Correct-answer positions are randomized in the six subject introductions and the current answer-checking quiz modules, including reading, conditionals, tense contrasts, file tracing, debugging, daily routines, animal groups and lineages, genetics, gene expression, cell-cycle, and animal-function practice. The option mapping stays stable while a learner answers and is reshuffled when an activity restarts or switches scenario. Ordered controls and numeric prediction inputs keep their meaningful order.<br>
  Позиции правильных ответов перемешиваются во вводных проверках шести направлений и во всех найденных проверках с выбором ответа: чтение, условные предложения и времена английского, обработка файловых ошибок, отладка, повседневные действия, группы и происхождение животных, генетика, экспрессия генов, клеточный цикл и зоология. Пока ученик отвечает, соответствие вариантов не меняется; при перезапуске задания или смене сценария порядок перемешивается заново. Управляющие последовательности и числовые вводы сохраняют смысловой порядок.

- Source tools display attribution and dates and can check a fixed allowlist of official URLs. These checks can identify changed or unavailable pages, but they do not automatically update or approve lesson text.<br>
  Инструменты источников показывают атрибуцию и даты и проверяют ограниченный список официальных URL. Эти проверки могут выявить изменившиеся или недоступные страницы, но не обновляют и не утверждают текст урока автоматически.

- Obsidian search and note saving are optional and require its local REST API. NotebookLM currently uses a manual workflow: export a lesson as Markdown and import it yourself; direct API integration and synchronization are not implemented.<br>
  Поиск в Obsidian и сохранение заметок доступны по желанию и требуют локального REST API. Сейчас NotebookLM используется вручную: экспортируйте урок в Markdown и импортируйте его самостоятельно; прямое подключение к API и синхронизация не реализованы.

- The physics starter includes interactive motion and measurement activities. One 3D prototype demonstrates one-dimensional motion under constant force; it is not a general-purpose physics simulator. Other starter visual exercises are 2D.<br>
  В начальном курсе физики есть интерактивные задания по движению и измерениям. Один 3D-прототип показывает одномерное движение под постоянной силой и не является универсальным физическим симулятором. Остальные начальные визуальные упражнения двумерные.

## What is still planned / Что ещё предстоит сделать

Full course coverage and subject-editor review; explanations for every exercise; a complete mastery model and adaptive study plan; broader randomized quiz coverage; richer subject-specific simulations, video, and 3D practice; broader source and license review; automatic editorial workflows; direct NotebookLM integration; and account-based cross-device sync are not complete. The draft branch contains a local editor for learner-created subjects, topics, and subtopics, including additions to built-in subjects; this feature is not in the published preview. Its code passed the current branch CI run, but still needs Mac acceptance. User-created notes can be sent to the tutor as context, but they are not automatically turned into a complete, source-verified course.<br>
Ещё не готовы: полное покрытие курсов и предметная редактура; разбор каждого упражнения; полноценная модель освоения и адаптивный учебный план; перемешивание ответов во всех тестах; более развитые предметные симуляции, видео и 3D-практика; расширенная проверка источников и лицензий; автоматизированные редакторские процессы; прямое подключение NotebookLM; синхронизация между устройствами через аккаунт. В рабочей ветке есть локальный редактор пользовательских предметов, тем и подтем, включая добавление тем во встроенные предметы; этой функции ещё нет в опубликованной сборке. Её код прошёл текущий CI рабочей ветки, но нужна приёмка на Mac. Заметки пользователя можно передать тьютору как контекст, но они не превращаются автоматически в полный курс с проверенными источниками.

The 8 October team feedback and its P0–P3 acceptance order are tracked in the detailed plan.<br>
Замечания команды от 8 октября и критерии приёмки P0–P3 записаны в подробном плане.

An approved-source check is not a guarantee that all course information is current or correct. Provider free tiers, model availability, and quotas can change; the app does not promise unlimited free AI access.<br>
Проверка одобренных источников не гарантирует, что вся информация в курсах актуальна или верна. Бесплатные тарифы, доступность моделей и квоты провайдеров могут меняться; приложение не обещает неограниченный бесплатный доступ к ИИ.

## Architecture / Архитектура

| Component | Компонент | Responsibility | Назначение |
|---|---|---|---|
| SwiftUI client | Клиент SwiftUI | macOS navigation, lessons, exercises, settings, and local progress. | Навигация macOS, уроки, упражнения, настройки и локальный прогресс. |
| FastAPI service | Сервис FastAPI | Tutor API, agent routing, course search, source status, and progress endpoints. | API тьютора, маршрутизация агентов, поиск по курсам, состояние источников и работа с прогрессом. |
| Local knowledge | Локальная база знаний | Course files and retrieval index stored on the learner’s device. | Файлы курсов и поисковый индекс на устройстве ученика. |
| Model providers | Провайдеры моделей | Ollama on-device and explicitly configured compatible cloud APIs. | Локальная Ollama и явно настроенные совместимые облачные API. |
| External learning tools | Внешние учебные инструменты | Optional Obsidian bridge and Markdown export for NotebookLM. | Необязательный мост к Obsidian и экспорт Markdown для NotebookLM. |

## Try the tutor backend / Запустить сервер тьютора

From the repository root, create a virtual environment, install the backend dependencies, copy the sample settings, and start the local API.<br>
В корне репозитория создайте виртуальное окружение, установите зависимости сервера, скопируйте пример настроек и запустите локальный API.

macOS and Linux / macOS и Linux:

~~~sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-orchestrator.txt
cp .env.example .env
python 01_Projects/orchestrator.py
~~~

Windows PowerShell / оболочка Windows PowerShell:

~~~powershell
py -3 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements-orchestrator.txt
Copy-Item .env.example .env
python 01_Projects/orchestrator.py
~~~

The service listens on 127.0.0.1:8000 by default. Keep it bound to loopback for local development; the service does not provide user-account authentication.<br>
По умолчанию сервер слушает 127.0.0.1:8000. При локальной разработке оставляйте его привязанным к loopback-адресу: сервер не использует авторизацию аккаунтов.

## Build and check / Собрать и проверить

To build the macOS app from source, open macOS/ColiDev/ColiDev.xcodeproj on a Mac with Xcode, select the ColiDev scheme, and run it. Windows cannot build this native macOS target. The Windows app and downloadable installers are later product work.<br>
Чтобы собрать приложение macOS из исходников, откройте macOS/ColiDev/ColiDev.xcodeproj на Mac с Xcode, выберите схему ColiDev и запустите её. Windows не может собрать эту нативную цель macOS. Windows-приложение и скачиваемые установщики — будущие этапы проекта.

Run the backend test suite with:<br>
Запустить проверки backend можно так:

~~~sh
python -m pip install -r requirements-test.txt
python -m pytest 01_Projects -q
~~~

Automated tests use mocked providers and do not spend API credits or confirm live-provider access. GitHub Actions builds for Apple Silicon and Intel and smoke-checks the packaged backend, but it does not replace hands-on acceptance on a physical Mac.<br>
В автоматических тестах используются заглушки провайдеров; они не расходуют API-кредиты и не подтверждают доступ к реальным моделям. GitHub Actions собирает приложение для Apple Silicon и Intel и проверяет упакованный сервер, но это не заменяет проверку на настоящем Mac.

## Privacy and cost / Приватность и расходы

On macOS, credentials saved through the app are stored in Keychain. The development .env file is ignored by Git. Never commit real provider or Obsidian credentials.<br>
В macOS ключи, сохранённые через приложение, помещаются в Keychain. Файл .env для разработки исключён из Git. Никогда не добавляйте реальные ключи провайдеров или Obsidian в репозиторий.

Automatic routing defaults to free-only routes. Potentially paid cloud models and Google Search require an explicit cost-policy change. Cloud requests may include the learner’s question and selected course context; the app shows a warning before those routes are enabled.<br>
Автоматическая маршрутизация по умолчанию ограничена бесплатными маршрутами. Потенциально платные облачные модели и Google Search требуют явного изменения политики расходов. Облачный запрос может содержать вопрос ученика и выбранный контекст курса; перед включением таких маршрутов приложение показывает предупреждение.

## Project documents / Документы проекта

- [Detailed project plan / Подробный план проекта](project-plan/README.md)
- [Feedback and acceptance criteria / Замечания и критерии приёмки](project-plan/categories/11-feedback-and-acceptance.md)
- [macOS app notes / Заметки по приложению macOS](macOS/ColiDev/README.md)
- [Backend notes / Заметки по backend](01_Projects/README.md)
- [Course catalog / Каталог курсов](02_Areas/README.md)
- [Current pull request / Текущий pull request](https://github.com/invinby/coli-dev/pull/4)
- [Project repository / Репозиторий проекта](https://github.com/invinby/coli-dev)

Every English description in this profile is followed immediately by its complete Russian version. Product identifiers, filenames, commands, model IDs, and API names are kept unchanged so they can be copied and searched.<br>
После каждого английского описания в этом профиле сразу приведён полный перевод на русский. Названия продукта, файлов, команд, моделей и API оставлены без изменений, чтобы их можно было копировать и искать.

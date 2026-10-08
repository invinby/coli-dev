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

GitHub Actions run [37715007577](https://github.com/invinby/coli-dev/actions/runs/37715007577) passed for app commit `787e8f6`: backend checks, Swift verifiers including official citation links, Apple Silicon and Intel app builds, bundled-backend smoke checks, and course-roadmap checks all succeeded. It contains `ColiDev-macos-arm64` (22,041,130 bytes) and `ColiDev-macos-x86_64` (22,949,523 bytes) test artifacts, available until 22 October 2026. Open the run page and download the artifact matching your Mac.<br>
Запуск GitHub Actions [37715007577](https://github.com/invinby/coli-dev/actions/runs/37715007577) успешно прошёл для коммита приложения `787e8f6`: backend-проверки, Swift-verifier, включая безопасные ссылки на официальные источники, сборки приложения для Apple Silicon и Intel, smoke-проверки встроенного backend и проверка учебных маршрутов прошли. В нём доступны тестовые архивы `ColiDev-macos-arm64` (22 041 130 байт) и `ColiDev-macos-x86_64` (22 949 523 байта) до 22 октября 2026 года. Откройте страницу запуска и скачайте архив для своего Mac.<br>

These CI artifacts are unsigned test builds, not a published release. CI verifies compilation and bundled-backend smoke checks; running the app and checking its real UI and model routes on a Mac still requires hands-on acceptance.<br>
Это неподписанные тестовые архивы CI, а не опубликованный релиз. CI проверяет сборку и smoke-проверку встроенного backend; запуск приложения и проверка реального интерфейса и маршрутов моделей на Mac всё ещё требуют ручной приёмки.

## Project profile / Профиль проекта

**In one sentence:** ColiDev is a native macOS platform for bilingual, adaptive learning across subjects, combining structured courses, interactive practice, learner-created study paths, progress-aware guidance, and a configurable AI tutor.<br>
**Коротко:** ColiDev — нативная платформа для macOS для двуязычного и адаптивного изучения разных предметов: последовательные курсы, интерактивная практика, пользовательские учебные маршруты, рекомендации с учётом прогресса и настраиваемый ИИ-тьютор.

### Product purpose / Назначение продукта

Help learners understand a subject from its foundations through advanced topics. The tutor supports learning; it does not replace a well-sourced curriculum, an instructor, or the learner’s own reasoning.<br>
Помогать изучать предмет от базовых понятий до углублённых тем. ИИ-тьютор поддерживает обучение, но не заменяет учебную программу с источниками, преподавателя или самостоятельное мышление ученика.

### Learning experience / Учебный процесс

Each study session should adapt to its subject and the learner: set a short goal, check prerequisites where useful, explain the idea, let the learner work with it, give specific feedback, and choose a suitable next step or review. Recommend progression from evidence across varied tasks; course completion, self-rating, and a single correct answer are not proof of mastery. Move from foundations toward advanced and scientific depth when the learner and subject are ready.<br>
Каждое занятие должно учитывать предмет и ученика: задавать короткую цель, при необходимости проверять необходимые знания, объяснять идею, давать с ней поработать, возвращать конкретную обратную связь и предлагать подходящий следующий шаг или повторение. Переход к новым темам нужно рекомендовать по результатам разных заданий; завершение курса, самооценка и один правильный ответ не доказывают освоение. От основ следует переходить к продвинутому и научному уровню, когда к этому готовы ученик и предмет.

### Priority fields and languages / Приоритетные предметы и языки

The first subject set is mathematics, English, physics, biology, zoology, and programming. Learners should be able to progress from foundations to advanced study in each field, with room to add more subjects and topics later.<br>
Начальный набор направлений: математика, английский язык, физика, биология, зоология и программирование. По каждому предмету ученик должен переходить от основ к углублённому изучению; позднее каталог можно расширять новыми предметами и темами.

Russian and English are product languages for the interface and learning materials. English examples used to teach English remain in English, with a complete Russian explanation or equivalent alongside them.<br>
Русский и английский — языки интерфейса и учебных материалов. Примеры на английском, которые нужны для изучения английского языка, остаются на английском; рядом приводится полный перевод или пояснение на русском.

### Learner-created curriculum / Предметы и темы, созданные учеником

Keep the built-in subject catalog, including Biology, and let each learner add their own subjects, topics, and subtopics with a clear `+` action. They should also be able to add topics inside a built-in subject. The tutor may help organize learner notes, while generated material must remain distinguishable from source-reviewed course content.<br>
Сохранять встроенный каталог предметов, включая биологию, и дать каждому ученику возможность создавать собственные предметы, темы и подтемы через понятное действие `+`. Темы также можно добавлять во встроенные предметы. ИИ-тьютор может помочь упорядочить заметки ученика, при этом созданные материалы должны быть явно отделены от курсов, прошедших проверку источников.

### AI, sources, and visual tools / ИИ, источники и наглядные материалы

The tutor should use the active subject, lesson, learner progress, and retrieved sources as context. The intended architecture combines local Ollama models with explicitly configured compatible cloud providers. Automatic routing defaults to free-only routes; a provider’s free quota or continued availability is never guaranteed.<br>
Тьютор должен учитывать выбранный предмет, урок, прогресс ученика и найденные источники. Целевая архитектура объединяет локальные модели Ollama с явно настроенными совместимыми облачными провайдерами. Автоматическая маршрутизация по умолчанию использует только бесплатные маршруты; бесплатная квота и постоянная доступность провайдера не гарантируются.

Use current official or primary sources where suitable. Show attribution and review dates, and send changed material through editorial review before revising a lesson. Do not treat source monitoring or RAG as automatic fact-checking or automatic course updates.<br>
Когда это уместно, использовать актуальные официальные или первичные источники. Показывать атрибуцию и даты проверки, а изменившиеся материалы отправлять на редакторскую проверку до обновления урока. Мониторинг источников и RAG не считать автоматической проверкой фактов или автоматическим обновлением курсов.

### Visual and hands-on learning / Наглядное обучение и практика

Choose diagrams, graphs, animations, interactive simulations, contextualized video, or manipulable 3D according to the topic. Let learners rotate, zoom, reveal, compare, or change parameters when those actions help explain a mechanism. State each model’s assumptions and limits, and provide a clear explanation and checkable learning task alongside it.<br>
Подбирать схемы, графики, анимации, интерактивные симуляции, видео с контекстом или управляемые 3D-модели под конкретную тему. Если это помогает объяснить механизм, ученик должен уметь вращать модель, менять масштаб, показывать детали, сравнивать объекты или менять параметры. Для каждой модели указывать предпосылки и ограничения, дополнять её понятным объяснением и заданием, которое проверяет понимание.

### Native macOS experience / Нативный интерфейс macOS

Use a focused learning dashboard with clear subject navigation, current progress, a useful next action, and truthful service and content states. Follow native macOS interaction patterns and Apple Human Interface Guidelines, with accessible controls, keyboard navigation, and recoverable error states. A missing lesson or unavailable model must lead to a clear explanation and next action.<br>
Сделать главным рабочим пространством учебную панель с понятной навигацией по предметам, текущим прогрессом, полезным следующим действием и достоверными статусами сервисов и материалов. Следовать нативным паттернам macOS и рекомендациям Apple Human Interface Guidelines; предусмотреть доступные элементы управления, навигацию с клавиатуры и восстановление после ошибок. Если урок отсутствует или модель недоступна, интерфейс должен ясно объяснить причину и предложить следующий шаг.

### Platform and integrations / Платформа и интеграции

The current client is a native SwiftUI macOS app backed by a local Python service. Obsidian is an optional local knowledge connection. NotebookLM currently has a manual Markdown export/import workflow; direct API integration and synchronization are not implemented.<br>
Текущий клиент — нативное приложение SwiftUI для macOS с локальным сервером на Python. Obsidian подключается как дополнительный локальный источник знаний. Сейчас NotebookLM поддерживается вручную через экспорт и импорт Markdown; прямое API-подключение и синхронизация не реализованы.

After the macOS product is ready, the planned expansion is a Windows app with functional parity, followed by a product website with downloadable installers. End users should not need to clone the Git repository to install the app.<br>
После готовности продукта для macOS планируется версия для Windows с теми же основными возможностями, а затем сайт продукта со скачиваемыми установщиками. Для установки пользователям не придётся клонировать Git-репозиторий.

### Current status / Текущий статус

ColiDev is an early team prototype, not a finished or bug-free product. The sections below distinguish working prototype features from planned work and from checks that still require hands-on acceptance on a Mac.<br>
ColiDev — ранний командный прототип, а не готовый продукт без ошибок. В разделах ниже отдельно описаны работающие функции, будущие задачи и проверки, для которых всё ещё нужна ручная приёмка на Mac.

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

- The draft Continue flow includes built-in lessons, learner-created subjects and topics, and topics added to built-in subjects. It prioritizes due review, an unfinished resumed topic, a low-recall revisit, then the next unfinished roadmap topic. Custom topics use stable progress IDs, learner-confirmed completion, and spaced-review status. These signals are self-reported and are not a full mastery model; Mac acceptance is still required.<br>
  Черновая логика «Продолжить» учитывает встроенные уроки, созданные учеником предметы и темы, а также темы, добавленные во встроенные предметы. Сначала предлагается просроченное повторение, затем незавершённая открытая тема, повтор темы с низкой самооценкой воспоминания и следующий незавершённый пункт учебного плана. У пользовательских тем есть постоянные ID прогресса, подтверждение завершения учеником и статус интервального повторения. Эти сигналы основаны на самооценке и ещё не образуют полноценную модель освоения; нужна проверка на Mac.

- The local backend serves the tutor, course retrieval, progress synchronization, service settings, and the loopback Obsidian bridge. The app can package and launch that backend runtime.<br>
  Локальный сервер обслуживает тьютора, поиск по курсам, синхронизацию прогресса, настройки сервисов и локальную интеграцию с Obsidian. Приложение умеет упаковывать и запускать этот сервер.

- AI routes can be configured by role. Local models now also have a direct sidebar entry, opening the Control Center on its Ollama availability, installed-models, and local-role screen. Paid cloud routes require a separate cost-policy setting; saving an API key does not enable them by itself.<br>
  Маршруты ИИ можно настраивать отдельно для разных ролей. Для локальных моделей теперь есть отдельный пункт в боковом меню: он сразу открывает экран Центра управления с доступностью Ollama, установленными моделями и назначениями локальных ролей. Для платных облачных маршрутов нужно отдельно разрешить расходы; одно сохранение ключа API само по себе их не включает.

- Tutor readiness distinguishes a responding local backend from a configured model route. The app does not treat internet access or an unused session allowance as proof that a model is ready.<br>
  Статус тьютора отдельно показывает, отвечает ли локальный сервер и настроен ли маршрут к модели. Наличие интернета или неиспользованной квоты сессии не считается подтверждением готовности модели.

- Settings include a real-reply check for the selected local or automatic tutor route. It sends only a short static prompt, skips course and Obsidian retrieval and web search, and reports the actual provider, model, response time, answer text, or error. A successful health check alone does not mark the model as verified. The request may use provider quota; paid routes still follow the explicit cost policy.<br>
  В настройках можно проверить реальный ответ выбранного локального или автоматического маршрута тьютора. Отправляется только короткий статический запрос; поиск по курсам и Obsidian, а также веб-поиск отключены. Приложение показывает фактического провайдера, модель, время ответа, текст ответа или ошибку. Успешная проверка health сама по себе не означает, что модель проверена. Запрос может расходовать квоту провайдера; платные маршруты по-прежнему подчиняются отдельной настройке расходов.

- The local RAG index searches course Markdown and text resources. It supports lexical search and optional Ollama embeddings; tutor retrieval is limited to a small number of sources for each answer.<br>
  Локальный индекс RAG ищет по Markdown-урокам и текстовым материалам. Доступен обычный текстовый поиск и необязательные векторные представления через Ollama; для ответа тьютору передаётся ограниченное число источников.

- Correct-answer positions are randomized in the six subject introductions and the current answer-checking quiz modules, including reading, conditionals, tense contrasts, file tracing, debugging, daily routines, animal groups and lineages, genetics, gene expression, cell-cycle, and animal-function practice. The option mapping stays stable while a learner answers and is reshuffled when an activity restarts, switches scenario, or the learner retries after a wrong answer. Ordered controls and numeric prediction inputs keep their meaningful order.<br>
  Позиции правильных ответов перемешиваются во вводных проверках шести направлений и во всех найденных проверках с выбором ответа: чтение, условные предложения и времена английского, обработка файловых ошибок, отладка, повседневные действия, группы и происхождение животных, генетика, экспрессия генов, клеточный цикл и зоология. Пока ученик отвечает, соответствие вариантов не меняется; порядок заново перемешивается при перезапуске задания, смене сценария или повторной попытке после неверного ответа. Управляющие последовательности и числовые вводы сохраняют смысловой порядок.

- Source tools display attribution and dates and can check a fixed allowlist of official URLs. These checks can identify changed or unavailable pages, but they do not automatically update or approve lesson text.<br>
  Инструменты источников показывают атрибуцию и даты и проверяют ограниченный список официальных URL. Эти проверки могут выявить изменившиеся или недоступные страницы, но не обновляют и не утверждают текст урока автоматически.

- Obsidian search and note saving are optional and require its local REST API. NotebookLM currently uses a manual workflow: export a lesson as Markdown and import it yourself; direct API integration and synchronization are not implemented.<br>
  Поиск в Obsidian и сохранение заметок доступны по желанию и требуют локального REST API. Сейчас NotebookLM используется вручную: экспортируйте урок в Markdown и импортируйте его самостоятельно; прямое подключение к API и синхронизация не реализованы.

- The physics starter includes interactive motion and measurement activities. One 3D prototype demonstrates one-dimensional motion under constant force; it is not a general-purpose physics simulator. Other starter visual exercises are 2D.<br>
  В начальном курсе физики есть интерактивные задания по движению и измерениям. Один 3D-прототип показывает одномерное движение под постоянной силой и не является универсальным физическим симулятором. Остальные начальные визуальные упражнения двумерные.

## What is still planned / Что ещё предстоит сделать

Full course coverage and subject-editor review; explanations for every exercise; a complete mastery model and adaptive study plan; broader randomized quiz coverage; richer subject-specific simulations, video, and 3D practice; broader source and license review; automatic editorial workflows; direct NotebookLM integration; and account-based cross-device sync are not complete. The draft branch contains a local editor for learner-created subjects, topics, and subtopics, including additions to built-in subjects, plus progress-aware Continue and review routing for those topics. Source commit `a1018aa` passed the [backend, Swift verifier, Apple Silicon, and Intel CI run](https://github.com/invinby/coli-dev/actions/runs/37711173529), including packaged-backend smoke checks. Hands-on acceptance on a Mac and a live model reply remain unverified. User-created notes can be sent to the tutor as context, but they are not automatically turned into a complete, source-verified course.<br>
Ещё не готовы: полное покрытие курсов и предметная редактура; разбор каждого упражнения; полноценная модель освоения и адаптивный учебный план; перемешивание ответов во всех тестах; более развитые предметные симуляции, видео и 3D-практика; расширенная проверка источников и лицензий; автоматизированные редакторские процессы; прямое подключение NotebookLM; синхронизация между устройствами через аккаунт. В рабочей ветке есть локальный редактор пользовательских предметов, тем и подтем, включая добавление тем во встроенные предметы, а также логика «Продолжить» и маршруты повторения с учётом прогресса этих тем. Исходный коммит `a1018aa` прошёл [CI backend, Swift-проверок и сборок Apple Silicon/Intel](https://github.com/invinby/coli-dev/actions/runs/37711173529), включая smoke-проверку упакованного backend. Ручная приёмка на Mac и живой ответ модели пока не проверены. Заметки пользователя можно передать тьютору как контекст, но они не превращаются автоматически в полный курс с проверенными источниками.

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
- [Biology source audit / Аудит источников уроков биологии](project-plan/research/biology-foundations-source-audit.md)
- [Current pull request / Текущий pull request](https://github.com/invinby/coli-dev/pull/4)
- [Project repository / Репозиторий проекта](https://github.com/invinby/coli-dev)

Every explanatory English passage in the README is followed immediately by its complete Russian version. Product identifiers, filenames, commands, model IDs, and API names stay unchanged so they can be copied and searched.<br>
После каждого пояснительного текста на английском в README сразу приведён его полный русский перевод. Названия продукта, файлов, команд, моделей и API оставлены без изменений, чтобы их можно было копировать и искать.

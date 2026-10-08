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

GitHub Actions run [37749853475](https://github.com/invinby/coli-dev/actions/runs/37749853475) passed for commit `5f9db48`: backend checks, Swift verifiers, Apple Silicon and Intel builds, bundled-backend smoke checks, and bundled-curriculum route checks all succeeded. The run produced `ColiDev-macos-arm64` (22,390,856 bytes) and `ColiDev-macos-x86_64` (23,295,238 bytes), available until 22 October 2026. This verifies CI builds, not a hands-on UI review on a Mac. Open the run page and download the artifact matching your Mac.<br>
Запуск GitHub Actions [37749853475](https://github.com/invinby/coli-dev/actions/runs/37749853475) прошёл для коммита `5f9db48`: backend-проверки, Swift-verifier'ы, сборки для Apple Silicon и Intel, smoke-проверки встроенного backend и проверка маршрутов учебных материалов завершились успешно. Созданы архивы `ColiDev-macos-arm64` (22 390 856 байт) и `ColiDev-macos-x86_64` (23 295 238 байт), доступны до 22 октября 2026 года. CI подтвердил сборку, но не ручную проверку интерфейса на Mac. Открой страницу запуска и скачай архив для своего Mac.<br>

These CI artifacts are unsigned test builds, not a published release. CI verifies compilation and bundled-backend smoke checks; running the app and checking its real UI and model routes on a Mac still requires hands-on acceptance.<br>
Эти тестовые архивы CI не подписаны и не являются опубликованным релизом. CI проверяет компиляцию и запуск встроенного сервера, но само приложение, его интерфейс и реальные ответы моделей всё ещё нужно вручную проверить на Mac.

## Project profile / Профиль проекта

**Product in one sentence:** ColiDev is a native macOS learning platform that combines source-aware courses, subject-specific interactive practice, learner-created study paths, saved progress, and a configurable AI tutor in Russian and English.<br>
**Продукт в одном предложении:** ColiDev — нативная учебная платформа для macOS, которая объединяет курсы с указанием источников, предметные интерактивные тренажёры, пользовательские учебные маршруты, сохранение прогресса и настраиваемого ИИ-тьютора на русском и английском языках.

### Product goal / Цель продукта

Help learners build a connected understanding of a subject, from prerequisites and foundations to advanced and scientific topics. The product must show why a next topic is recommended and make it easy to practise, revisit, or move ahead.<br>
Помогать ученику выстроить целостное понимание предмета: от необходимых предварительных знаний и основ до углублённых и научных тем. Приложение должно объяснять, почему предлагает следующую тему, и давать возможность потренироваться, повторить материал или двигаться дальше.

This is the product brief for the complete educational app: what learners can do, how lessons and evidence work, how services connect, and what remains to be built. The tutor is one part of that product, not the product brief itself.<br>
Это описание всего образовательного приложения: что делает ученик, как устроены уроки и результаты проверок, как подключаются сервисы и что ещё предстоит разработать. ИИ-тьютор — лишь одна часть продукта, а не само описание продукта.

### Subject scope and languages / Предметы и языки

The starting subject set is mathematics, English, physics, biology, zoology, and programming. Biology remains its own built-in subject; zoology is available as a separate, related field. The catalogue should grow without forcing every subject into the same course template.<br>
Стартовый набор направлений: математика, английский язык, физика, биология, зоология и программирование. Биология остаётся отдельным встроенным предметом; зоология доступна как самостоятельная связанная область. Каталог должен расширяться, а структура курса — учитывать особенности предмета, а не загонять все темы в один шаблон.

Russian and English are supported product languages for both the interface and learning materials. For English-language study, keep the examples learners need to see in English and put a full Russian translation or explanation alongside them.<br>
Русский и английский поддерживаются как языки интерфейса и учебных материалов. В уроках английского примеры, которые ученик должен видеть на английском, сохраняются; рядом размещается полный русский перевод или пояснение.

### Lesson design and progression / Структура уроков и продвижение

Lessons should combine a short goal, the explanation, a worked example, a subject-appropriate activity, practice, feedback, and a check of understanding. Build each roadmap from foundations toward advanced study; a roadmap entry is not a promise that its lesson is already written or reviewed. Recommendations may use several signals, but completion, self-rating, or one correct answer alone must never be presented as mastery.<br>
В уроке должны быть короткая цель, объяснение, разобранный пример, подходящая предмету интерактивная задача, практика, обратная связь и проверка понимания. Учебный план ведёт от основ к углублённому материалу; наличие темы в плане не означает, что урок уже написан и проверен. Рекомендации могут опираться на разные сигналы, но завершение, самооценка или один правильный ответ сами по себе не должны выдаваться за освоение темы.

### Adaptive learning and depth / Адаптивное обучение и глубина

Start with a lightweight check of prior knowledge and keep evidence for each topic. Move from prerequisites and foundations toward advanced work, and toward scientific depth when it fits the discipline and the learner's goal. Skip or shorten material only when more than one suitable check supports that decision; when a learner struggles, fill the prerequisite gap or change the explanation, example, visual, or practice instead of repeating the same lecture. Use active recall, spaced review, increasing challenge, and new problems that test transfer. Show why the next topic is recommended and what evidence would justify moving on.<br>
Начинать с короткой проверки уже имеющихся знаний и сохранять результаты отдельно по каждой теме. Вести от предпосылок и основ к продвинутому уровню, а к научной глубине — когда это уместно для предмета и цели ученика. Сокращать или пропускать материал только при подтверждении несколькими подходящими проверками; при трудностях закрывать пробел в предпосылках или менять объяснение, пример, визуальный формат либо практику, а не повторять ту же лекцию. Использовать активное вспоминание, интервальные повторы, постепенное усложнение и новые задачи на перенос знаний. Показывать, почему рекомендована следующая тема и какие результаты позволят перейти дальше.

Use discipline-specific teaching methods rather than one fixed lesson template: mathematical reasoning and proofs, physical models and experiments, biological structures and processes, zoological comparisons with stated limits, practical programming and debugging, and active language use. Let learners revisit a topic, ask for another explanation, or move to a harder challenge when their evidence supports it.<br>
Подбирать обучение под предмет, а не загонять всё в один шаблон: математические рассуждения и доказательства, физические модели и эксперименты, биологические структуры и процессы, сравнение животных с явными ограничениями, практическое программирование и отладка, активная языковая практика. Давать возможность повторить тему, запросить другое объяснение или перейти к более сложной задаче, если результаты это подтверждают.

### Learner-created study paths / Пользовательские учебные маршруты

Keep the built-in subjects, and let learners add their own subjects, topics, and nested subtopics. They can also add a personal topic inside a built-in subject without overwriting its shipped curriculum. Clearly distinguish learner-authored material from lessons reviewed against external sources.<br>
Сохранять встроенные предметы и позволить ученику создавать собственные предметы, темы и вложенные подтемы. Пользовательскую тему можно добавить и во встроенный предмет, не перезаписывая исходную программу. Материалы ученика необходимо явно отделять от уроков, сверенных с внешними источниками.

### AI tutor and model routing / ИИ-тьютор и выбор моделей

The tutor should receive only relevant lesson, learner-progress, and retrieved-source context. The target design combines local Ollama models with user-configured compatible cloud providers and role-specific model routes; specialist agents may help with a subject while a coordinator prepares the final response. Automatic routing starts with free-only routes. A provider can change or remove its free quota, and model quality or availability is not guaranteed.<br>
Тьютор должен получать только нужный контекст урока, прогресса ученика и найденных источников. Целевая архитектура объединяет локальные модели Ollama с настроенными пользователем совместимыми облачными провайдерами и выбором модели для каждой роли; по отдельным предметам могут помогать специализированные агенты, а координатор готовит итоговый ответ. Автоматическая маршрутизация изначально ограничивается бесплатными маршрутами. Провайдер может изменить или убрать бесплатную квоту, а качество и доступность моделей не гарантируются.

Use current official or primary sources where possible. Show the source, its publication or revision date when known, and our last review date. Retrieval augmented generation (RAG) brings relevant indexed material into a response; it does not prove that a claim is true or silently rewrite a course. A detected source change should go to editorial review before approved lesson content changes.<br>
По возможности использовать актуальные официальные или первичные источники. Указывать источник, дату публикации или редакции при наличии и дату нашей последней проверки. Retrieval augmented generation (RAG, генерация с поиском по источникам) подбирает подходящие проиндексированные материалы для ответа, но не доказывает истинность утверждений и не переписывает курс незаметно для команды. Обнаруженные изменения источника должны попасть на редакторскую проверку, прежде чем менять утверждённый текст урока.

### Interactive and visual learning / Интерактивное и наглядное обучение

Choose diagrams, graphs, experiments, video, and manipulable 3D because they explain a specific concept, not as decoration. Let learners change parameters or inspect a model, then ask them to predict or explain an outcome. Every simulation must state its assumptions and limits and remain usable alongside a text explanation and accessible controls.<br>
Выбирать схемы, графики, эксперименты, видео и управляемые 3D-модели потому, что они объясняют конкретное понятие, а не ради украшения. Ученик должен менять параметры или исследовать модель, а затем предсказывать или объяснять результат. Для каждой симуляции указывать допущения и ограничения; рядом должны оставаться текстовое объяснение и доступные элементы управления.

### Native macOS product and control center / Нативное приложение и центр управления

The main screen should help a learner choose a subject, see saved progress, and continue with a clear next step. The Control Center should make provider and model routes, Ollama status, source connections, and cost policy understandable and editable. Keep service health separate from a successful real model reply. Use native macOS interaction patterns and Apple Human Interface Guidelines: clear hierarchy, accessible labels, keyboard support, and recoverable error states—not a generic neon AI dashboard.<br>
Главный экран должен помогать выбрать предмет, увидеть сохранённый прогресс и продолжить обучение с понятного следующего шага. В Центре управления нужно ясно показывать и настраивать маршруты провайдеров и моделей, состояние Ollama, подключение источников и политику расходов. Статус сервиса необходимо отличать от успешного реального ответа модели. Использовать нативные паттерны macOS и рекомендации Apple Human Interface Guidelines: понятную иерархию, доступные подписи, управление с клавиатуры и восстановление после ошибок — без шаблонной неоновой панели «про ИИ».

### Sources, integrations, and privacy / Источники, интеграции и приватность

The current client is a SwiftUI macOS app backed by a local Python service. Obsidian is an optional local source connection. For personal Gemini Notebook (NotebookLM), ColiDev exports Markdown for the learner to import manually; no consumer API or automatic sync is documented in the official sources reviewed. A separate Google Cloud API exists for Gemini Notebook Enterprise, but it is Preview and requires Enterprise setup and licensing. See the [official integration research / исследование официальной интеграции](project-plan/research/gemini-notebook-official-integration.md).<br>
Текущий клиент — приложение SwiftUI для macOS с локальным сервисом на Python. Obsidian подключается как дополнительный локальный источник. Для личного Gemini Notebook (NotebookLM) ColiDev экспортирует Markdown, который ученик импортирует вручную; в проверенных официальных источниках не документированы потребительский API и автоматическая синхронизация. Отдельный API Google Cloud существует для Gemini Notebook Enterprise, но он находится в Preview и требует корпоративной настройки и лицензирования. Подробности — в [исследовании официальной интеграции](project-plan/research/gemini-notebook-official-integration.md).

Cloud requests may include lesson or learner context, so the app must disclose the selected route and whether content leaves the device. Keep learner progress local unless a future sync feature is explicitly enabled by the learner.<br>
Облачный запрос может содержать контекст урока или ученика, поэтому приложение должно показывать выбранный маршрут и сообщать, покидают ли данные устройство. Учебный прогресс хранится локально; будущая синхронизация появится только после явного включения этой функции учеником.

### Future platforms / Будущие платформы

After a stable macOS release, the planned next steps are a Windows app with equivalent core workflows and a product website that distributes signed installers. End users should not have to clone the source repository to install ColiDev.<br>
После стабильного выпуска для macOS планируется приложение для Windows с теми же основными сценариями, затем сайт продукта для распространения подписанных установщиков. Для установки ColiDev пользователям не придётся клонировать репозиторий с исходным кодом.

### Current product status / Текущий статус продукта

ColiDev is an early team prototype, not a finished, signed, or bug-free release. The following section separates working prototype features from planned work and Mac checks that still need hands-on acceptance.<br>
ColiDev — ранний командный прототип, а не готовый, подписанный или полностью проверенный релиз. Следующий раздел отделяет уже работающие функции прототипа от будущих задач и проверок, которые ещё нужно вручную выполнить на Mac.

## What works in the prototype / Что работает в прототипе

- The macOS app contains six subject areas, lesson pages, interactive exercises, and locally saved study progress. The six directions are a starting catalog, not complete courses.<br>
  Приложение macOS содержит шесть направлений, страницы уроков, интерактивные упражнения и локальное сохранение прогресса. Это начальный каталог, а не шесть завершённых курсов.

- The repository contains 49 bilingual lesson files. They are a starter collection; coverage and academic review vary by subject and level.<br>
  В репозитории есть 49 двуязычных файлов уроков. Это начальная подборка; полнота и академическая проверка различаются по предметам и уровням.

- The mathematics starter includes a sourced RU/EN lesson and an interactive graph lab for quadratic functions. Learners predict a transformation, adjust `a`, `h`, and `k`, and inspect the graph, vertex, axis of symmetry, and real roots. The CI build and bundled lesson route passed; hands-on visual review on a Mac remains to be done.<br>
  В начальном курсе математики есть двуязычный урок с источником и интерактивная лаборатория графиков квадратичной функции. Ученик сначала предсказывает преобразование, затем меняет `a`, `h` и `k` и исследует график, вершину, ось симметрии и действительные корни. Сборка CI и проверка наличия урока в bundle прошли; вручную оценить отображение на Mac ещё предстоит.

- The course maps are planned from foundational material toward advanced topics. A topic listed in a roadmap does not necessarily have a finished lesson yet.<br>
  Карты курсов ведут от основ к углублённым темам. Наличие темы в плане не означает, что готовый урок уже написан.

- Zoology now links an advanced bilingual lesson on avian heat stress to a rotatable 3D schematic and range comparison based on a 2025 thick-billed murre field study. The lesson distinguishes air temperature, operative temperature, and the study-specific stress criterion.<br>
  В зоологии появился углублённый двуязычный урок о тепловом стрессе птиц с вращаемой 3D-схемой и сравнением диапазонов по полевому исследованию толстоклювых кайр 2025 года. Урок разделяет температуру воздуха, оперативную температуру и критерий стресса именно из этого исследования.

- Lesson progress is saved locally and supports review scheduling. Course completion and actual mastery are separate product goals; the prototype does not yet provide a complete mastery model.<br>
  Прогресс уроков сохраняется локально и используется для планирования повторений. Завершение курса и реальное освоение материала — разные цели; в прототипе пока нет полной модели оценки знаний.

- The home screen counts completed lessons and roadmap topics with saved checks, and flags topics that need reinforcement. One zoology thermoregulation lab also records typed interactive-prediction evidence, which contributes to check coverage and can recommend a retry. This is evidence coverage, not a mastery score; only that lab is connected so far, and its evidence does not complete the lesson or change spaced-review scheduling.<br>
  Главный экран считает завершённые уроки и темы учебных планов с сохранёнными проверками, а также отмечает темы, которые нужно закрепить. Один зоологический тренажёр по терморегуляции также сохраняет отдельное свидетельство интерактивного предсказания: оно входит в покрытие проверками и может привести к рекомендации повторить тему. Это покрытие результатов, а не оценка освоения знаний; пока подключён только этот тренажёр, и его результат сам по себе не завершает урок и не меняет расписание интервального повторения.

- The draft Continue flow includes built-in lessons, learner-created subjects and topics, and topics added to built-in subjects. It prioritizes a due review, an unfinished resumed topic, a topic whose knowledge check took multiple attempts, low self-rated recall, then the next unfinished roadmap topic. Custom topics use stable progress IDs, learner-confirmed completion, and spaced-review status. These signals do not form a complete mastery model; Mac acceptance is still required.<br>
  Черновая логика «Продолжить» учитывает встроенные уроки, созданные учеником предметы и темы, а также темы, добавленные во встроенные предметы. Сначала предлагается просроченное повторение, затем незавершённая открытая тема, тема, где проверочный вопрос потребовал нескольких попыток, повтор темы с низкой самооценкой воспоминания и следующий незавершённый пункт учебного плана. У пользовательских тем есть постоянные ID прогресса, подтверждение завершения учеником и статус интервального повторения. Эти сигналы ещё не образуют полноценную модель освоения; нужна проверка на Mac.

- **RU/EN knowledge-check evidence:** Completing or reviewing a full curriculum lesson records attempts and first-try correctness for its multiple-choice check. Evidence waits in the local queue while the backend is offline, is stored in SQLite, and is included in progress backups. Continue may recommend practice on that topic before a new one.<br>
  **Результаты проверок в уроках на русском и английском:** При завершении или повторении полноценного урока сохраняются число попыток и правильность первого ответа на вопрос с выбором ответа. Если backend недоступен, событие остаётся в локальной очереди; затем оно хранится в SQLite и включается в резервную копию прогресса. «Продолжить» может предложить закрепить эту тему до перехода к новой.

- **RU/EN interactive-practice evidence:** The zoology thermoregulation lab records each prediction attempt as `interactive_prediction` and reports the latest result separately from lesson completion and spaced review. Events are queued offline and included in the assessment history used for backup and coverage. This first vertical slice does not yet cover the other practice modules or constitute a validated mastery model.<br>
  **Результаты интерактивной практики на русском и английском:** Зоологический тренажёр по терморегуляции сохраняет каждую попытку предсказания как `interactive_prediction` и учитывает последний результат отдельно от завершения урока и интервального повторения. При отключённом backend события ждут отправки; история результатов участвует в резервном копировании и подсчёте покрытия. Этот первый законченный срез пока не охватывает остальные тренажёры и не является проверенной моделью освоения знаний.

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

Full course coverage and subject-editor review; explanations for every exercise; a complete mastery model and adaptive study plan; broader randomized quiz coverage; richer subject-specific simulations, video, and 3D practice; broader source and license review; automatic editorial workflows; direct NotebookLM integration; and account-based cross-device sync are not complete. The current branch also contains a local editor for learner-created subjects, topics, and subtopics, including additions to built-in subjects, plus progress-aware Continue and review routing. Commit `53d6f64` passed backend tests, every Swift verifier, Apple Silicon and Intel builds, bundled-backend smoke checks, and curriculum checks in [GitHub Actions](https://github.com/invinby/coli-dev/actions/runs/37735488289). Hands-on acceptance on a Mac and a live model reply remain unverified. User-created notes can be sent to the tutor as context, but they are not automatically turned into a complete, source-verified course.<br>
Ещё не готовы: полное покрытие курсов и предметная редактура; разбор каждого упражнения; полноценная модель освоения и адаптивный учебный план; перемешивание ответов во всех тестах; более развитые предметные симуляции, видео и 3D-практика; расширенная проверка источников и лицензий; автоматизированные редакторские процессы; прямое подключение NotebookLM; синхронизация между устройствами через аккаунт. В текущей ветке также есть локальный редактор пользовательских предметов, тем и подтем, включая добавление тем во встроенные предметы, а также рекомендации «Продолжить» и повторения с учётом прогресса. Коммит `53d6f64` прошёл backend-тесты, все проверки Swift, сборки для Apple Silicon и Intel, smoke-проверки встроенного backend и проверку учебных планов в [GitHub Actions](https://github.com/invinby/coli-dev/actions/runs/37735488289). Ручная приёмка на Mac и живой ответ модели пока не проверены. Заметки пользователя можно передать тьютору как контекст, но они не превращаются автоматически в полный курс с проверенными источниками.

The 8 October team feedback and its P0–P3 acceptance order are tracked in the detailed plan.<br>
Замечания команды от 8 октября и критерии приёмки P0–P3 записаны в подробном плане.

An approved-source check is not a guarantee that all course information is current or correct. Provider free tiers, model availability, and quotas can change; the app does not promise unlimited free AI access.<br>
Проверка одобренных источников не гарантирует, что вся информация в курсах актуальна или верна. Бесплатные тарифы, доступность моделей и квоты провайдеров могут меняться; приложение не обещает неограниченный бесплатный доступ к ИИ.

## Architecture / Архитектура

| Component | Компонент | Responsibility | Назначение |
|---|---|---|---|
| SwiftUI client | Клиент SwiftUI | macOS navigation, lessons, exercises, settings, and local progress. | Навигация macOS, уроки, упражнения, настройки и локальный прогресс. |
| FastAPI service | Сервис FastAPI | Tutor API, agent routing, course search, source status, and progress endpoints. | API тьютора, маршрутизация агентов, поиск по курсам, состояние источников и работа с прогрессом. |
| Local knowledge | Локальная база знаний | Course files and retrieval index stored on the learner’s device. Retrieved Obsidian citations can include the note’s filesystem modification time when its plugin exposes it. | Файлы курсов и поисковый индекс на устройстве ученика. В найденных заметках Obsidian может показываться время изменения файла, если плагин предоставляет такие метаданные. |
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
- [Bilingual application-development prompt / Двуязычный промпт на разработку приложения](project-plan/APP_BUILD_PROMPT.md)
- [Feedback and acceptance criteria / Замечания и критерии приёмки](project-plan/categories/11-feedback-and-acceptance.md)
- [macOS app notes / Заметки по приложению macOS](macOS/ColiDev/README.md)
- [Backend notes / Заметки по backend](01_Projects/README.md)
- [Course catalog / Каталог курсов](02_Areas/README.md)
- [Biology source audit / Аудит источников уроков биологии](project-plan/research/biology-foundations-source-audit.md)
- [Current pull request / Текущий pull request](https://github.com/invinby/coli-dev/pull/4)
- [Project repository / Репозиторий проекта](https://github.com/invinby/coli-dev)

Every explanatory English passage in the README is followed immediately by its complete Russian version. Product identifiers, filenames, commands, model IDs, and API names stay unchanged so they can be copied and searched.<br>
После каждого пояснительного текста на английском в README сразу приведён его полный русский перевод. Названия продукта, файлов, команд, моделей и API оставлены без изменений, чтобы их можно было копировать и искать.

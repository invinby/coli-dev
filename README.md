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

GitHub Actions run [37790495394](https://github.com/invinby/coli-dev/actions/runs/37790495394) passed for code commit `2c35d06`: all 481 backend tests, all Swift verifiers, Apple Silicon and Intel builds, packaged-backend smoke checks, and all 50 curriculum-route checks succeeded. The physics `F=ma` lab now records interactive-prediction attempts. Unsigned test archives are `ColiDev-macos-arm64` (22,628,091 bytes) and `ColiDev-macos-x86_64` (23,534,389 bytes), available until 22 October 2026. CI verifies compilation, packaging, and route checks; hands-on UI acceptance and a live model reply on a Mac remain separate. Open the run page and download the archive matching your Mac.<br>
Запуск GitHub Actions [37790495394](https://github.com/invinby/coli-dev/actions/runs/37790495394) прошёл для кодового коммита `2c35d06`: успешно завершились все 481 backend-тест, все Swift-проверки, сборки для Apple Silicon и Intel, smoke-проверки упакованного backend и проверки всех 50 маршрутов учебной программы. В физическом тренажёре `F=ma` теперь сохраняются попытки интерактивного прогноза. Неподписанные тестовые архивы `ColiDev-macos-arm64` (22 628 091 байт) и `ColiDev-macos-x86_64` (23 534 389 байт) доступны до 22 октября 2026 года. CI проверяет компиляцию, упаковку и маршруты, но ручная приёмка интерфейса и живой ответ модели на Mac остаются отдельными проверками. Открой страницу запуска и скачай архив для своего Mac.<br>

These CI artifacts are unsigned test builds, not a published release. CI verifies compilation and bundled-backend smoke checks; running the app and checking its real UI and model routes on a Mac still requires hands-on acceptance.<br>
Эти тестовые архивы CI не подписаны и не являются опубликованным релизом. CI проверяет компиляцию и запуск встроенного сервера, но само приложение, его интерфейс и реальные ответы моделей всё ещё нужно вручную проверить на Mac.

## Product profile / Профиль продукта

**One-sentence description:** ColiDev is a native macOS learning workspace that guides each learner from foundations toward advanced understanding through structured courses, subject-specific practice, visual exploration, and evidence-based next-step recommendations.<br>
**В одном предложении:** ColiDev — нативная учебная среда для macOS, которая помогает каждому ученику пройти от основ к углублённому пониманию через последовательные курсы, предметную практику, визуальное исследование и рекомендации следующих шагов по результатам проверок.

### Subjects and languages / Предметы и языки

**EN:** The starting catalogue covers mathematics, English, physics, biology, zoology, and programming. Biology is already a built-in subject. Learners can create their own subjects, topics, and nested subtopics, or add topics to an existing subject. The interface and learning materials support both Russian and English.<br>
**RU:** Стартовый каталог охватывает математику, английский язык, физику, биологию, зоологию и программирование. Биология уже входит во встроенный каталог. Ученик может создавать собственные предметы, темы и подтемы, а также добавлять темы в существующие предметы. Интерфейс и учебные материалы доступны на русском и английском.

### Learning experience / Как устроено обучение

**EN:** A lesson may combine a short goal, an explanation, a worked example, a subject-appropriate visual, independent practice, feedback on errors, a new check for understanding, saved progress, and a recommended next step. The sequence changes with the subject and the learner; one rigid lesson template should not be forced onto every field.<br>
**RU:** Урок может объединять короткую цель, объяснение, разобранный пример, подходящую предмету визуализацию, самостоятельную практику, разбор ошибок, новую проверку понимания, сохранение результата и рекомендацию следующего шага. Последовательность меняется с учётом предмета и ученика; единый жёсткий шаблон не должен применяться ко всем направлениям.

### Adaptive study path / Персональный учебный маршрут

**EN:** The product goal is to use topic-level evidence, prerequisites, recurring errors, practice results, and review history to choose what the learner should do next. A self-rating can prompt a closer check, but it is not proof of mastery. The current prototype has limited prerequisite-based recommendations; a complete mastery model and broad diagnostic placement are still planned.<br>
**RU:** Цель продукта — использовать результаты по каждой теме, её предпосылки, повторяющиеся ошибки, итоги практики и историю повторений, чтобы выбирать следующий шаг ученика. Самооценка может стать поводом для дополнительной проверки, но не доказывает освоение темы. В текущем прототипе есть ограниченные рекомендации по предпосылкам; полная модель освоения и широкая входная диагностика ещё планируются.

**EN:** For important topics, the intended learning path distinguishes familiarity, explaining in one's own words, routine application, transfer to a new problem, understanding mechanisms and limits, advanced analysis, and formal or scientific work where appropriate. Evidence should include more than a single multiple-choice answer: explanation, varied practice, reasoning, error-finding, and transfer. A knowledge map should show prerequisites and links between ideas. These are product requirements; the prototype does not yet calculate a complete mastery level.<br>
**RU:** Для важных тем планируемый маршрут различает знакомство, объяснение своими словами, стандартное применение, перенос на новую задачу, понимание механизмов и ограничений, углублённый анализ, а при необходимости — формальную или научную работу. Свидетельства понимания должны выходить за рамки одного тестового ответа: нужны объяснение, разнообразная практика, рассуждение, поиск ошибок и перенос знаний. Карта знаний должна показывать предпосылки и связи между идеями. Это требования к продукту; прототип пока не рассчитывает полный уровень освоения.

### Visual and interactive practice / Наглядная и интерактивная практика

**EN:** Choose a format for the concept: a graph, labelled diagram, experiment, simulation, video with questions, or a manipulable 3D model. Use 3D when learners benefit from rotating, zooming, or examining parts; make controls, assumptions, and limits clear. Track which topics have a finished visual module so a roadmap never implies that an unfinished activity is ready.<br>
**RU:** Формат выбирается по содержанию темы: график, подписанная схема, опыт, симуляция, видео с вопросами или управляемая 3D-модель. 3D нужна там, где ученику помогает вращать, приближать или рассматривать части объекта; управление, допущения и ограничения должны быть понятны. Готовность визуальных модулей отслеживается по темам, чтобы карта курса не выдавала незавершённую активность за готовую.

### AI, sources, and control center / ИИ, источники и центр управления

**EN:** The target architecture combines local Ollama models with optional OpenAI-compatible online providers. Each AI role can have its own provider and model; free-only routing is the default, and potentially paid routes stay disabled until the learner explicitly changes the cost policy. The local RAG index can retrieve course material and selected connected sources. Source checks and review dates can flag work for an editor, but they do not prove that a claim is true or silently rewrite a lesson. The Control Center is intended to manage course status, source provenance and review, indexing, providers and models per role, service diagnostics, and cost settings.<br>
**RU:** Целевая архитектура объединяет локальные модели Ollama и подключаемые онлайн-провайдеры, совместимые с OpenAI API. Для каждой роли ИИ можно выбрать свой провайдер и модель; по умолчанию маршруты ограничены бесплатными, а потенциально платные отключены, пока ученик явно не изменит политику расходов. Локальный RAG-индекс ищет по курсам и выбранным подключённым источникам. Проверки источников и даты пересмотра помогают назначить редакторскую проверку, но не доказывают истинность утверждения и не переписывают урок автоматически. В центре управления предполагается вести статусы курсов, происхождение и проверку источников, индексацию, провайдеры и модели по ролям, диагностику сервисов и расходы.

### Privacy, integrations, and design / Приватность, интеграции и дизайн

**EN:** Learner progress is stored locally. macOS credentials saved through the app use Keychain. Obsidian can connect through its local REST API. For personal NotebookLM, the supported workflow is Markdown export and manual import; direct consumer API access and automatic sync are not documented by the reviewed official sources. Cloud routes must disclose when learner context leaves the device. The interface follows native macOS patterns and Apple Human Interface Guidelines, with clear hierarchy, accessible controls, and recoverable errors.<br>
**RU:** Учебный прогресс хранится локально. В macOS ключи, сохранённые через приложение, помещаются в Keychain. Obsidian подключается через локальный REST API. Для личного NotebookLM предусмотрен экспорт в Markdown и ручной импорт; прямой потребительский API и автоматическая синхронизация не описаны в проверенных официальных источниках. При отправке контекста через облачный маршрут приложение должно сообщать, что данные покидают устройство. Интерфейс следует нативным правилам macOS и Apple Human Interface Guidelines: понятная иерархия, доступное управление и восстановимые ошибки.

### Platform plan / Платформы

**EN:** macOS is the first target. After the Mac app is stable, the team plans a Windows app with equivalent core workflows and a product website for signed installers. Users should not need to clone GitHub to install the product.<br>
**RU:** Сначала разрабатывается версия для macOS. После стабилизации приложения для Mac команда планирует версию для Windows с теми же основными сценариями и сайт продукта с подписанными установщиками. Для установки пользователям не придётся клонировать GitHub.

**Full application brief / Полное техническое задание:** [Development prompt / Промпт разработки приложения](project-plan/APP_BUILD_PROMPT.md). Current implementation and known limits are listed in the sections below.<br>
**Полное техническое задание:** [Промпт разработки приложения](project-plan/APP_BUILD_PROMPT.md). Реализация и известные ограничения описаны ниже.
## What works in the prototype / Что работает в прототипе

- The macOS app contains six subject areas, lesson pages, interactive exercises, and locally saved study progress. The six directions are a starting catalog, not complete courses.<br>
  Приложение macOS содержит шесть направлений, страницы уроков, интерактивные упражнения и локальное сохранение прогресса. Это начальный каталог, а не шесть завершённых курсов.

- The repository contains 50 bilingual lesson files. They are a starter collection; coverage and academic review vary by subject and level.<br>
  В репозитории есть 50 двуязычных файлов уроков. Это начальная подборка; полнота и академическая проверка различаются по предметам и уровням.

- The mathematics starter includes a sourced RU/EN lesson and an interactive graph lab for quadratic functions. Learners predict a transformation, adjust `a`, `h`, and `k`, and inspect the graph, vertex, axis of symmetry, and real roots. The CI build and bundled lesson route passed; hands-on visual review on a Mac remains to be done.<br>
  В начальном курсе математики есть двуязычный урок с источником и интерактивная лаборатория графиков квадратичной функции. Ученик сначала предсказывает преобразование, затем меняет `a`, `h` и `k` и исследует график, вершину, ось симметрии и действительные корни. Сборка CI и проверка наличия урока в bundle прошли; вручную оценить отображение на Mac ещё предстоит.

- The branch adds an advanced constrained-optimization lesson based on OpenStax Calculus Volume 3 §§4.7–4.8 and a draggable unit-circle lab. Commit `c4e2244` passed the Swift verifier and native Apple Silicon and Intel builds in [CI run 37782398587](https://github.com/invinby/coli-dev/actions/runs/37782398587); hands-on visual review on a Mac remains open.<br>
  В ветку добавлены углублённый урок по оптимизации с ограничением на основе *Calculus Volume 3* §§4.7–4.8 от OpenStax и интерактивная единичная окружность с перемещаемой точкой. Коммит `c4e2244` прошёл Swift-verifier и нативные сборки для Apple Silicon и Intel в [CI 37782398587](https://github.com/invinby/coli-dev/actions/runs/37782398587); вручную проверить отображение на Mac ещё предстоит.

- The course maps are planned from foundational material toward advanced topics. A topic listed in a roadmap does not necessarily have a finished lesson yet.<br>
  Карты курсов ведут от основ к углублённым темам. Наличие темы в плане не означает, что готовый урок уже написан.

- Zoology now links an advanced bilingual lesson on avian heat stress to a rotatable 3D schematic and range comparison based on a 2025 thick-billed murre field study. The lesson distinguishes air temperature, operative temperature, and the study-specific stress criterion.<br>
  В зоологии появился углублённый двуязычный урок о тепловом стрессе птиц с вращаемой 3D-схемой и сравнением диапазонов по полевому исследованию толстоклювых кайр 2025 года. Урок разделяет температуру воздуха, оперативную температуру и критерий стресса именно из этого исследования.

- Lesson progress is saved locally and supports review scheduling. Course completion and actual mastery are separate product goals; the prototype does not yet provide a complete mastery model.<br>
  Прогресс уроков сохраняется локально и используется для планирования повторений. Завершение курса и реальное освоение материала — разные цели; в прототипе пока нет полной модели оценки знаний.

- The home screen counts completed lessons and roadmap topics with saved checks, and flags topics that need reinforcement. The zoology thermoregulation lab and the physics net-force lab record typed interactive-prediction evidence; these results contribute to check coverage and can recommend practice. This is evidence coverage, not a mastery score; neither lab result completes the lesson or changes spaced-review scheduling.<br>
  Главный экран считает завершённые уроки и темы учебных планов с сохранёнными проверками, а также отмечает темы, которые нужно закрепить. Зоологический тренажёр по терморегуляции и физический тренажёр равнодействующей силы сохраняют типизированные результаты интерактивных прогнозов; они входят в покрытие проверками и могут привести к рекомендации закрепить тему. Это покрытие результатов, а не оценка освоения знаний; результат ни одного из этих тренажёров сам по себе не завершает урок и не меняет расписание интервального повторения.

- The prototype's Continue flow includes built-in lessons, learner-created subjects and topics, and topics added to built-in subjects. It prioritizes a due review, an unfinished resumed topic, repeated self-reported difficulty, a topic whose knowledge check took multiple attempts, low self-rated recall, then the next unfinished roadmap topic. When the learner repeatedly reports a foundation gap, it returns to a specific parent prerequisite only if that prerequisite's own latest knowledge check failed with the same reported category; otherwise it stays on the current topic. Custom topics use stable progress IDs, learner-confirmed completion, and spaced-review status. These signals do not form a complete mastery model; Mac acceptance is still required.<br>
  В прототипе «Продолжить» учитывает встроенные уроки, созданные учеником предметы и темы, а также темы, добавленные во встроенные предметы. Сначала предлагается просроченное повторение, затем незавершённая открытая тема, повторяющаяся самооценка трудности, тема, где проверочный вопрос потребовал нескольких попыток, тема с низкой самооценкой воспоминания и следующий незавершённый пункт учебного плана. Если ученик несколько раз отмечает нехватку основы, приложение возвращается к конкретной родительской предпосылке только тогда, когда её последняя проверка знаний тоже не пройдена с той же категорией; иначе рекомендация остаётся на текущей теме. У пользовательских тем есть постоянные ID прогресса, подтверждение завершения учеником и статус интервального повторения. Эти сигналы ещё не образуют полноценную модель освоения; нужна проверка на Mac.

- **RU/EN knowledge-check evidence:** Completing or reviewing a full curriculum lesson records attempts and first-try correctness for its multiple-choice check. Evidence waits in the local queue while the backend is offline, is stored in SQLite, and is included in progress backups. Continue may recommend practice on that topic before a new one.<br>
  **Результаты проверок в уроках на русском и английском:** При завершении или повторении полноценного урока сохраняются число попыток и правильность первого ответа на вопрос с выбором ответа. Если backend недоступен, событие остаётся в локальной очереди; затем оно хранится в SQLite и включается в резервную копию прогресса. «Продолжить» может предложить закрепить эту тему до перехода к новой.

- **RU/EN interactive-practice evidence:** The zoology thermoregulation lab and physics net-force lab record each prediction attempt as `interactive_prediction`, separately from lesson completion and spaced review. Events are queued offline and included in assessment history, backups, and check coverage. Other practice modules are not yet connected; this does not constitute a validated mastery model.<br>
  **Результаты интерактивной практики на русском и английском:** Зоологический тренажёр по терморегуляции и физический тренажёр равнодействующей силы сохраняют каждую попытку предсказания как `interactive_prediction`, отдельно от завершения урока и интервального повторения. При отключённом backend события ждут отправки; история результатов участвует в резервном копировании и подсчёте покрытия проверками. Остальные тренажёры пока не подключены; это не является проверенной моделью освоения знаний.

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

- After a wrong answer in six introductory quizzes and 50 linked lesson checks, the app withholds the answer and explanation until the learner retries or asks to reveal them. A correct answer shows the explanation automatically. Feedback coverage for other interactive-practice formats still needs review.<br>
  После неправильного ответа в шести вводных тестах и 50 связанных проверках уроков приложение скрывает правильный ответ и объяснение, пока ученик не повторит попытку или сам не попросит показать разбор. После верного ответа объяснение появляется автоматически. Обратную связь в остальных форматах интерактивной практики ещё нужно проверить.

- Obsidian search and note saving are optional and require its local REST API. NotebookLM currently uses a manual workflow: export a lesson as Markdown and import it yourself; direct API integration and synchronization are not implemented.<br>
  Поиск в Obsidian и сохранение заметок доступны по желанию и требуют локального REST API. Сейчас NotebookLM используется вручную: экспортируйте урок в Markdown и импортируйте его самостоятельно; прямое подключение к API и синхронизация не реализованы.

- The physics starter includes interactive motion and measurement activities. One 3D prototype demonstrates one-dimensional motion under constant force; it is not a general-purpose physics simulator. Other starter visual exercises are 2D.<br>
  В начальном курсе физики есть интерактивные задания по движению и измерениям. Один 3D-прототип показывает одномерное движение под постоянной силой и не является универсальным физическим симулятором. Остальные начальные визуальные упражнения двумерные.

## What is still planned / Что ещё предстоит сделать

Full verified course coverage and subject-content review; a complete mastery model and adaptive study plan; explanatory feedback across every exercise type; richer subject-specific simulations, video, and 3D practice; verified source and license review; automatic editorial workflows; direct NotebookLM integration; and account-based cross-device sync are not complete. The prototype now has one narrow evidence-based foundation-remediation recommendation, not a full mastery model: a repeated "foundation gap" self-report routes to an earlier prerequisite only when that prerequisite's own latest knowledge check failed with the same category. Self-report alone does not redirect learning. The current branch also contains a local editor for learner-created subjects and topics, plus a tutor-generated versioned JSON outline that learners can review, edit, remove, and explicitly save beneath the selected topic. It is not a complete, source-verified course. Code commit `6d17936` passed 481 backend tests, all Swift verifiers, Apple Silicon and Intel builds, packaged-backend smoke checks, and all 50 curriculum-route checks in [GitHub Actions](https://github.com/invinby/coli-dev/actions/runs/37785278768). Test archives `ColiDev-macos-arm64` (22,597,892 bytes) and `ColiDev-macos-x86_64` (23,503,565 bytes) are available until 22 October 2026. Hands-on acceptance on a Mac and a live model reply remain unverified.<br>
Ещё не готовы: полное проверенное покрытие курсов и предметная редактура; полноценная модель освоения и адаптивный учебный план; объясняющая обратная связь во всех форматах упражнений; более развитые предметные симуляции, видео и 3D-практика; редакторская проверка источников и лицензий; автоматизированные редакторские процессы; прямое подключение NotebookLM; синхронизация между устройствами через аккаунт. В прототип добавлена одна узкая рекомендация по подтверждённому пробелу в основе, но это не полная модель освоения: повторная самооценка «не хватает основы» ведёт к предыдущей предпосылке только если её последняя проверка знаний не пройдена с той же категорией. Одна самооценка сама по себе не меняет маршрут. В текущей ветке также есть локальный редактор пользовательских предметов и тем и версионируемый черновик структуры от тьютора: ученик может проверить, изменить или удалить пункты и явно сохранить их под выбранной темой. Это не полный курс с проверенными источниками. Кодовый коммит `6d17936` прошёл 481 backend-тест, все Swift-verifier, сборки для Apple Silicon и Intel, smoke-проверки упакованного backend и проверку всех 50 маршрутов в [GitHub Actions](https://github.com/invinby/coli-dev/actions/runs/37785278768). Тестовые архивы `ColiDev-macos-arm64` (22 597 892 байта) и `ColiDev-macos-x86_64` (23 503 565 байт) доступны до 22 октября 2026 года. Ручная приёмка на Mac и живой ответ модели ещё не подтверждены.<br>

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

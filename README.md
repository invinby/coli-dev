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

## Latest verified code build / Последняя проверенная сборка кода

GitHub Actions run [37838914330](https://github.com/invinby/coli-dev/actions/runs/37838914330) passed for commit `6ead9c5`: the backend suite, all Swift verifiers, Apple Silicon and Intel Xcode builds, bundled-backend smoke checks, and all 50 curriculum-route checks succeeded. The tutor composer now has separate readiness checks for the local service, route status, Auto route, local model, and whether Ollama is actually on this Mac; it displays the matching recovery guidance in Russian or English. Unsigned test archives are `ColiDev-macos-arm64` (22,796,581 bytes, through 22 October 2026 20:26 UTC) and `ColiDev-macos-x86_64` (23,751,833 bytes, through 22 October 2026 20:30 UTC). CI verifies compilation and packaging, not the live response of a user's selected provider; hands-on UI acceptance and that live reply still need to be checked on a Mac.<br>
Запуск GitHub Actions [37838914330](https://github.com/invinby/coli-dev/actions/runs/37838914330) успешно прошёл для коммита `6ead9c5`: прошли backend suite, все Swift-verifier, сборки Xcode для Apple Silicon и Intel, smoke-проверки встроенного backend и проверка всех 50 маршрутов курса. Для поля тьютора теперь отдельно проверяются локальный сервис, статус маршрута, маршрут «Авто», локальная модель и подтверждение, что Ollama действительно работает на этом Mac; при блокировке показывается подходящая инструкция на русском или английском. Неподписанные тестовые архивы `ColiDev-macos-arm64` (22 796 581 байт, до 22 октября 2026 года 20:26 UTC) и `ColiDev-macos-x86_64` (23 751 833 байта, до 22 октября 2026 года 20:30 UTC). CI проверяет компиляцию и упаковку, но не фактический ответ выбранного провайдера; интерфейс и живой ответ модели всё ещё нужно проверить на Mac.<br>

These CI artifacts are unsigned test builds, not a published release. CI verifies compilation and bundled-backend smoke checks; running the app and checking its real UI and model routes on a Mac still requires hands-on acceptance.<br>
Эти тестовые архивы CI не подписаны и не являются опубликованным релизом. CI проверяет компиляцию и запуск встроенного сервера, но само приложение, его интерфейс и реальные ответы моделей всё ещё нужно вручную проверить на Mac.

<a id="project-profile"></a>
## Профиль проекта / Project profile

**Кратко:** ColiDev — нативная учебная платформа для macOS, которая помогает изучать предметы от основ до углублённого и подходящего научного уровня с помощью курсов, предметной практики, визуальных объяснений и проверяемых рекомендаций.<br>
**In brief:** ColiDev is a native macOS learning platform that helps learners move from foundations toward advanced and, where suitable, scientific study through courses, subject-specific practice, visual explanations, and evidence-based recommendations.

### Предметы и языки / Subjects and languages

**RU:** Стартовый набор включает математику, английский язык, физику, биологию, зоологию и программирование. Биология уже является встроенным предметом. Ученик также может создавать собственные предметы, темы и подтемы или добавлять темы в существующие предметы. Интерфейс и учебные материалы поддерживают русский и английский языки.<br>
**EN:** The starting set includes mathematics, English, physics, biology, zoology, and programming. Biology is already a built-in subject. Learners can also create subjects, topics, and subtopics or add topics to existing subjects. The interface and learning materials support Russian and English.

### Как устроено обучение / How learning works

**RU:** Приложение должно вести от базовых понятий к самостоятельному применению, новым задачам, глубокому пониманию механизмов и ограничений, а затем — к продвинутой и уместной научной работе. Уроки сочетают теорию, примеры, практику, разбор ошибок, проверку понимания и следующий шаг. Порядок и метод меняются под предмет и уровень ученика — единого шаблона для всех дисциплин нет.<br>
**EN:** The app should guide learners from foundational concepts to independent application, unfamiliar problems, deep understanding of mechanisms and limits, and then to advanced and appropriate scientific work. Lessons combine theory, examples, practice, error feedback, checks for understanding, and a next step. The sequence and method adapt to the subject and learner; there is no single template for every discipline.

### Персональный маршрут и прогресс / Adaptive path and progress

**RU:** Система должна учитывать предпосылки, ответы, повторяющиеся ошибки, практику и историю повторения, чтобы выбрать полезный следующий шаг. Самооценка помогает решить, что проверить, но сама по себе не доказывает освоение. В прототипе уже есть ограниченные рекомендации по предпосылкам; полная модель освоения, широкая входная диагностика и оценка переноса знаний ещё разрабатываются. Прогресс прохождения курса нужно показывать отдельно от подтверждённого понимания.<br>
**EN:** The system should use prerequisites, answers, recurring errors, practice, and review history to select a useful next step. Self-ratings can help decide what to check, but they do not prove mastery by themselves. The prototype has limited prerequisite-based recommendations; a complete mastery model, broad placement diagnostics, and transfer-of-learning assessment are still being developed. Course completion should be shown separately from demonstrated understanding.

### Наглядность и практика / Visual learning and practice

**RU:** Для каждой темы подбирается подходящий формат: график, схема, опыт, симуляция, видео с вопросами или управляемая 3D-модель. 3D используется там, где вращение, приближение или разбор частей помогает понять тему. Управление, допущения и ограничения визуализации должны быть видны. В готовности курса нельзя показывать незавершённые тренажёры как рабочие.<br>
**EN:** Choose a suitable format for each topic: a graph, diagram, experiment, simulation, video with questions, or a manipulable 3D model. Use 3D when rotating, zooming, or examining parts helps explain the concept. Make controls, assumptions, and visualization limits clear. Course status must not present unfinished activities as working ones.

### ИИ, источники и центр управления / AI, sources, and Control Center

**RU:** Приложение сочетает локальные модели Ollama с настраиваемыми онлайн-провайдерами, совместимыми с OpenAI API. Для ролей ИИ предусмотрен выбор провайдера и модели; по умолчанию действуют бесплатные маршруты, а потенциально платные требуют явного разрешения. Отдельный экран локальных моделей и часть центра управления уже реализованы. Ограниченный RAG использует учебные материалы и выбранные проверяемые источники. Проверка URL и дата пересмотра помогают поставить редакторскую задачу, но не подтверждают каждое утверждение и не обновляют текст урока автоматически. Поле тьютора различает недоступный локальный сервис, неизвестный статус маршрута, отсутствие доступного маршрута «Авто», неподготовленную локальную модель и Ollama за пределами этого Mac; для каждой причины показывается восстановительная подсказка. Это не доказывает, что выбранная модель действительно ответит: для этого есть отдельная проверка реального ответа. Полноценное администрирование материалов и рабочих процессов остаётся задачей разработки.<br>
**EN:** The app combines local Ollama models with configurable online providers that support the OpenAI API. AI roles can select a provider and model; free routes are the default, and potentially paid routes require explicit permission. A dedicated Local Models screen and part of the Control Center are already implemented. Limited RAG uses course materials and selected reviewable sources. URL checks and review dates can create editorial work, but they do not validate every claim or automatically update lesson text. The tutor composer distinguishes an unavailable local service, unknown route status, a missing Auto route, an unavailable local model, and Ollama running somewhere other than this Mac; it shows recovery guidance for each state. This does not prove that the selected model will answer; the separate real-reply check does that. Complete course administration and editorial workflows remain to be built.

### Приватность, интеграции и дизайн / Privacy, integrations, and design

**RU:** Учебный прогресс хранится локально, а сохранённые приложением macOS-учётные данные помещаются в Keychain. Obsidian подключается через локальный REST API. Для личного NotebookLM сейчас доступен ручной сценарий: экспорт урока в Markdown и импорт пользователем; прямой потребительский API и синхронизация не реализованы. При отправке контекста облачной модели интерфейс должен ясно сообщать об этом. Дизайн опирается на нативный SwiftUI и Apple Human Interface Guidelines: понятная иерархия, доступные элементы управления и восстановимые ошибки.<br>
**EN:** Learning progress is stored locally, and macOS credentials saved by the app use Keychain. Obsidian connects through its local REST API. For personal NotebookLM, the supported workflow is manual: export a lesson to Markdown and import it yourself; a direct consumer API and synchronization are not implemented. The interface must clearly disclose when context is sent to a cloud model. The design follows native SwiftUI and Apple Human Interface Guidelines, with clear hierarchy, accessible controls, and recoverable errors.

### Платформы / Platforms

**RU:** Сначала команда выпускает стабильное приложение для macOS. После этого планируются версия для Windows с теми же основными сценариями и сайт с подписанными установщиками. Для установки готового продукта пользователям не придётся клонировать GitHub.<br>
**EN:** The team will stabilize and release the macOS app first. A Windows version with equivalent core workflows and a website for signed installers are planned afterward. Users will not need to clone GitHub to install the finished product.

**Полное техническое задание:** [Промпт разработки приложения](project-plan/APP_BUILD_PROMPT.md). Это задание для разработки всей платформы, а не системный промпт для отдельного ИИ-тьютора.<br>
**Full application brief:** [ColiDev development prompt](project-plan/APP_BUILD_PROMPT.md). It specifies the whole platform, not the system prompt for a standalone AI tutor.

Текущая реализация и ограничения перечислены ниже.<br>
Current implementation and limitations are listed below.
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

- The home screen counts completed lessons and roadmap topics with saved checks, and flags topics that need reinforcement. The zoology thermoregulation lab, physics net-force lab, mathematics linear-systems lab, biology osmosis lab, and Python loop-tracing lab record typed interactive-prediction evidence; these results contribute to check coverage and can recommend practice. This is evidence coverage, not a mastery score; no lab result completes the lesson or changes spaced-review scheduling.<br>
  Главный экран считает завершённые уроки и темы учебных планов с сохранёнными проверками, а также отмечает темы, которые нужно закрепить. Зоологический тренажёр по терморегуляции, физический тренажёр равнодействующей силы, математический тренажёр систем уравнений, биологический тренажёр осмоса и Python-тренажёр трассировки цикла сохраняют типизированные результаты интерактивных прогнозов; они входят в покрытие проверками и могут привести к рекомендации закрепить тему. Это покрытие результатов, а не оценка освоения знаний; результат ни одного из этих тренажёров сам по себе не завершает урок и не меняет расписание интервального повторения.

- The prototype's Continue flow includes built-in lessons, learner-created subjects and topics, and topics added to built-in subjects. It prioritizes a due review, an unfinished resumed topic, repeated self-reported difficulty, a topic whose knowledge check took multiple attempts, low self-rated recall, then the next unfinished roadmap topic. When the learner repeatedly reports a foundation gap, it returns to a specific parent prerequisite only if that prerequisite's own latest knowledge check failed with the same reported category; otherwise it stays on the current topic. Custom topics use stable progress IDs, learner-confirmed completion, and spaced-review status. These signals do not form a complete mastery model; Mac acceptance is still required.<br>
  В прототипе «Продолжить» учитывает встроенные уроки, созданные учеником предметы и темы, а также темы, добавленные во встроенные предметы. Сначала предлагается просроченное повторение, затем незавершённая открытая тема, повторяющаяся самооценка трудности, тема, где проверочный вопрос потребовал нескольких попыток, тема с низкой самооценкой воспоминания и следующий незавершённый пункт учебного плана. Если ученик несколько раз отмечает нехватку основы, приложение возвращается к конкретной родительской предпосылке только тогда, когда её последняя проверка знаний тоже не пройдена с той же категорией; иначе рекомендация остаётся на текущей теме. У пользовательских тем есть постоянные ID прогресса, подтверждение завершения учеником и статус интервального повторения. Эти сигналы ещё не образуют полноценную модель освоения; нужна проверка на Mac.

- **RU/EN knowledge-check evidence:** Completing or reviewing a full curriculum lesson records attempts and first-try correctness for its multiple-choice check. Evidence waits in the local queue while the backend is offline, is stored in SQLite, and is included in progress backups. Continue may recommend practice on that topic before a new one.<br>
  **Результаты проверок в уроках на русском и английском:** При завершении или повторении полноценного урока сохраняются число попыток и правильность первого ответа на вопрос с выбором ответа. Если backend недоступен, событие остаётся в локальной очереди; затем оно хранится в SQLite и включается в резервную копию прогресса. «Продолжить» может предложить закрепить эту тему до перехода к новой.

- **RU/EN interactive-practice evidence:** The biology osmosis, zoology thermoregulation, physics net-force, and mathematics linear-systems labs record each prediction attempt as `interactive_prediction`, separately from lesson completion and spaced review. Events are queued offline and included in assessment history, backups, and check coverage. Other practice modules are not yet connected; this does not constitute a validated mastery model.<br>
  **Результаты интерактивной практики на русском и английском:** Биологический тренажёр осмоса, зоологический тренажёр по терморегуляции, физический тренажёр равнодействующей силы и математический тренажёр систем уравнений сохраняют каждую попытку предсказания как `interactive_prediction`, отдельно от завершения урока и интервального повторения. При отключённом backend события ждут отправки; история результатов участвует в резервном копировании и подсчёте покрытия проверками. Остальные тренажёры пока не подключены; это не является проверенной моделью освоения знаний.

- The local backend serves the tutor, course retrieval, progress synchronization, service settings, and the loopback Obsidian bridge. The app can package and launch that backend runtime.<br>
  Локальный сервер обслуживает тьютора, поиск по курсам, синхронизацию прогресса, настройки сервисов и локальную интеграцию с Obsidian. Приложение умеет упаковывать и запускать этот сервер.

- AI routes can be configured by role. Local models now also have a direct sidebar entry, opening the Control Center on its Ollama availability, installed-models, and local-role screen. Paid cloud routes require a separate cost-policy setting; saving an API key does not enable them by itself.<br>
  Маршруты ИИ можно настраивать отдельно для разных ролей. Для локальных моделей теперь есть отдельный пункт в боковом меню: он сразу открывает экран Центра управления с доступностью Ollama, установленными моделями и назначениями локальных ролей. Для платных облачных маршрутов нужно отдельно разрешить расходы; одно сохранение ключа API само по себе их не включает.

- Tutor readiness distinguishes a responding local backend from a configured model route. When sending is blocked, the composer identifies the missing layer and gives localized next steps; internet access or an unused session allowance is never treated as proof that a model is ready.<br>
  Статус тьютора отдельно показывает, отвечает ли локальный сервер и настроен ли маршрут к модели. Если отправка заблокирована, поле ввода называет недостающий компонент и подсказывает следующий шаг на выбранном языке; наличие интернета или неиспользованной квоты не считается подтверждением готовности модели.

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

## Что ещё предстоит сделать / What remains

**Уже есть в прототипе / Already in the prototype:** локальный редактор предметов и тем; ограниченные рекомендации по подтверждённым предпосылкам; перемешивание вариантов с сохранением ответа на время попытки; подсказка и повтор в Python-тренажёре трассировки цикла; локальный индекс и проверка источников по разрешённому списку; центр управления с диагностикой и настройками маршрутов ИИ. Это проверяемые части прототипа, а не доказательство полноты курса или готовности релиза.<br>
**Already in the prototype:** a local subject and topic editor; limited recommendations based on confirmed prerequisites; shuffled answer choices with stable mapping during an attempt; a hint and retry in the Python loop-tracing activity; a local index and allowlisted source checks; and a Control Center with diagnostics and AI-route settings. These are prototype features, not proof of complete courses or release readiness.

**Главные незавершённые задачи / Main work still to do:**

- **RU:** Проверить содержание и источники каждого готового урока, расширить курсы по всем шести направлениям и явно показывать, какие темы готовы, а какие ещё нет.<br>
  **EN:** Review the content and sources of each finished lesson, expand courses across all six subjects, and clearly show which topics are ready and which are not.
- **RU:** Развить ограниченные рекомендации до адаптивного плана с диагностикой, предпосылками, анализом ошибок, изменением сложности и проверкой переноса знаний. Не выдавать завершение уроков за процент мастерства.<br>
  **EN:** Grow the limited recommendations into an adaptive plan with diagnostics, prerequisites, error analysis, difficulty adjustment, and transfer checks. Do not present lesson completion as a mastery percentage.
- **RU:** Провести аудит обратной связи во всех форматах упражнений и обеспечить понятный разбор ответов, повторную попытку и помощь без преждевременного раскрытия решения.<br>
  **EN:** Audit feedback across every exercise format and provide clear explanations, retries, and useful help without revealing solutions too early.
- **RU:** Расширить предметные схемы, симуляции, видео с вопросами и 3D-модули там, где они помогают понять тему; отдельно описывать управление, допущения и ограничения каждой модели.<br>
  **EN:** Expand subject-specific diagrams, simulations, videos with questions, and 3D activities where they aid understanding; document each model's controls, assumptions, and limits.
- **RU:** Завершить редакторский процесс для источников и уроков. Текущая проверка источников выявляет изменения и поддерживает ограниченный RAG, но не обновляет и не публикует текст урока без проверки.<br>
  **EN:** Complete the editorial workflow for sources and lessons. Current source checks can detect changes and support limited RAG, but lesson text is not updated or published without review.
- **RU:** Доработать центр управления: редактирование версий курсов, просмотр состава RAG, диагностика и более полный экспорт/восстановление данных. Сейчас доступна только часть этой панели.<br>
  **EN:** Complete the Control Center with course-version editing, RAG inspection, diagnostics, and fuller data export and restore. Only part of this administration area exists today.
- **RU:** Проверить приложение вручную на целевом Mac, включая интерфейс, клавиатурную доступность, Keychain и настоящий ответ выбранной модели. Успешная CI-сборка не заменяет эту приёмку.<br>
  **EN:** Review the app hands-on on the target Mac, including its interface, keyboard accessibility, Keychain, and a real reply from the selected model. A successful CI build does not replace this acceptance.
- **RU:** Для NotebookLM пока остаётся ручной экспорт/импорт Markdown; прямую интеграцию добавлять только при наличии официально поддерживаемого способа. Синхронизация между устройствами также не реализована.<br>
  **EN:** NotebookLM currently uses manual Markdown export and import; add direct integration only if an officially supported method is available. Cross-device synchronization is also not implemented.
- **RU:** После стабильного релиза macOS подготовить Windows-версию и сайт с подписанными установщиками, чтобы пользователям не приходилось скачивать исходники через GitHub.<br>
  **EN:** After a stable macOS release, prepare a Windows version and an installer website so users do not need to download source code through GitHub.

Порядок P0–P3 и критерии приёмки замечаний команды от 8 октября записаны в [подробном плане](project-plan/categories/11-feedback-and-acceptance.md).<br>
The P0–P3 order and acceptance criteria for the team's 8 October feedback are recorded in the [detailed plan](project-plan/categories/11-feedback-and-acceptance.md).

Проверка одобренных источников не гарантирует, что вся информация в курсах актуальна или верна. Бесплатные тарифы, доступность моделей и квоты провайдеров меняются; приложение не обещает неограниченный бесплатный доступ или полное отсутствие ошибок.<br>
An approved-source check does not guarantee that every course statement is current or correct. Provider free tiers, model availability, and quotas can change; the app does not promise unlimited free access or a complete absence of bugs.

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

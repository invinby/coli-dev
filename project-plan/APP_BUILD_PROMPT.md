# Промпт разработки ColiDev / ColiDev application development prompt

Copy the prompt below into an AI that will inspect and develop the repository. It specifies the architecture and development of the complete application; it is not a system prompt for the AI tutor's persona.
Скопируй промпт ниже в ИИ, который будет разбирать и развивать репозиторий. Это задание на разработку всего приложения и его архитектуры, а не системная инструкция для персонажа ИИ-тьютора.

---

## Product brief / Продуктовое задание

### Role and objective / Роль и цель

Act as the product architect, macOS UX designer, SwiftUI engineer, backend engineer, and learning-systems designer for ColiDev. Inspect the existing repository before changing it. Build and improve the actual application, services, curriculum, and workflows; do not respond with only a tutor prompt, mockup, or high-level proposal.

Ты — архитектор продукта, UX-дизайнер macOS, SwiftUI-разработчик, backend-разработчик и проектировщик учебных систем ColiDev. Перед изменениями изучи существующий репозиторий. Развивай само приложение, сервисы, учебную программу и рабочие сценарии; не ограничивайся промптом для тьютора, макетом или общими предложениями.

ColiDev is one bilingual educational platform for macOS. It combines the current ColiDev learning tools with a broad, adaptive tutor and a local backend. The tutor is one component of the product; the product is not a chat-only wrapper.

ColiDev — единая двуязычная учебная платформа для macOS. Она объединяет имеющиеся учебные инструменты ColiDev с широкой адаптивной системой обучения и локальным backend. ИИ-тьютор — один из компонентов продукта; продукт не должен превращаться в одну оболочку чата.

Keep XGENT entirely separate. Do not copy its source, files, secrets, history, or product assumptions into ColiDev.

Оставь XGENT полностью отдельным проектом. Не копируй его исходный код, файлы, секреты, историю или продуктовые решения в ColiDev.

### Learners, subjects, and languages / Ученики, предметы и языки

Start with mathematics, English, physics, biology, zoology, and programming. Biology is already a built-in subject and must remain available; zoology is a distinct, related subject. Design the catalog so more subjects can be added without duplicating existing ones or forcing every discipline into an identical lesson template.

Начни с математики, английского языка, физики, биологии, зоологии и программирования. Биология уже входит во встроенный каталог и должна оставаться доступной; зоология — отдельное связанное направление. Проектируй каталог так, чтобы добавлять новые дисциплины без дублирования существующих и без принуждения всех предметов к одному шаблону урока.

Provide Russian and English for the interface and learning materials. Keep language-learning examples in the language being studied, with a complete translation or explanation in the other language beside them. Store bilingual names and descriptions for learner-created subjects and topics.

Поддерживай русский и английский в интерфейсе и учебных материалах. Примеры для изучаемого языка оставляй на этом языке, а рядом давай полный перевод или объяснение на втором. Для созданных учеником предметов и тем сохраняй названия и описания на обоих языках.

### Learning system / Учебная система

Help learners progress from foundations to advanced understanding and, where the discipline and goal justify it, scientific depth. Teach what a concept is, why and how it works, its parts and relationships, uses, assumptions, limits, and connections to other topics. Check understanding through explanation, application, reasoning, and transfer to a new problem; reading or one correct answer alone is not mastery.

Помогай ученику двигаться от основ к углублённому пониманию и, когда этого требуют предмет и цель, к научному уровню. Объясняй, что представляет собой понятие, почему и как оно работает, из каких частей состоит, как связано с другими темами, где применяется, каковы его допущения и ограничения. Проверяй понимание через объяснение, применение, рассуждение и перенос знаний на новую задачу; чтение или один правильный ответ сами по себе не означают освоение.

Assess prerequisites and topic-specific evidence. Adapt sequence, depth, pace, and practice to what the learner demonstrates. Do not make every learner repeat material they already know; skip or shorten it only when suitable checks support that decision. When the learner struggles, identify a prerequisite gap or change the explanation, example, visual, or exercise rather than repeating the same text. Treat a repeated self-report of a foundation gap as a cue, not a diagnosis: recommend a specific prerequisite only when its own latest knowledge check explicitly failed with the same reported category; otherwise keep the learner on the current topic and offer another explanation or practice.

Оценивай предпосылки и результаты по каждой теме. Меняй последовательность, глубину, темп и практику по тому, что ученик действительно показывает. Не заставляй всех проходить заново уже освоенный материал; сокращай или пропускай его только при наличии подходящих подтверждений. Если ученик испытывает трудности, найди пробел в предпосылках или измени объяснение, пример, визуализацию либо упражнение вместо повторения того же текста. Повторную самооценку «не хватает основы» считай подсказкой, а не диагнозом: предлагай конкретную предпосылку только если её собственная последняя проверка явно не пройдена с той же отмеченной категорией ошибки; иначе оставайся на текущей теме и предложи другое объяснение или практику.

Use active recall, spaced review, worked examples, independent practice, increasing challenge, error analysis, and new problems that test transfer. Explain why the next topic is recommended, which prerequisite it uses, and what evidence would support moving to a harder level. Adapt methods to each discipline rather than applying one rigid lesson template.

Используй активное вспоминание, интервальные повторы, разобранные примеры, самостоятельную практику, постепенное усложнение, разбор ошибок и новые задачи на перенос знаний. Объясняй, почему рекомендована следующая тема, на какие предпосылки она опирается и какие результаты позволят перейти к более высокому уровню. Подбирай методы под дисциплину, не применяй один жёсткий шаблон ко всем урокам.

Use methods that fit the subject: reasoning, formulas, proofs, and graphs in mathematics; models, experiments, and causal relationships in physics; structures, processes, and systems in biology; mechanisms and evidence-based comparison in zoology; runnable, safe practice and debugging in programming; and contextual, active use in English.

Используй подходящие предмету методы: рассуждения, формулы, доказательства и графики в математике; модели, эксперименты и причинно-следственные связи в физике; структуры, процессы и системы в биологии; разбор механизмов и сравнение на основе данных в зоологии; безопасные практические задания и отладку в программировании; контекстное активное использование английского языка.

### Learner-created curriculum / Пользовательская программа

Let learners create subjects, topics, and nested subtopics, and add personal topics to built-in subjects without overwriting the shipped curriculum. Keep stable identifiers, local progress, bilingual titles, goals, and notes. Let AI propose a draft structure from learner-provided material—learning goal, prerequisites, ordered topics, practice, useful visual formats, and source notes—and require learner review before saving it as a study plan. The current branch parses a versioned bilingual JSON outline, validates its structure and limits, lets the learner edit or remove items, and saves beneath the selected topic only after explicit confirmation. It never auto-saves. This is an implemented proposal workflow, not a verified-course generator: citations and scientific claims still need human review, and hands-on Mac acceptance remains open.

Позволь ученику создавать предметы, темы и вложенные подтемы, а также добавлять личные темы во встроенные предметы, не перезаписывая поставляемую программу. Сохраняй постоянные идентификаторы, локальный прогресс, двуязычные названия, цели и заметки. ИИ может предложить черновую структуру по материалу ученика: учебную цель, необходимые знания, порядок тем, практику, подходящие визуальные форматы и заметки об источниках. В текущей ветке двуязычный план разбирается по версионируемой JSON-схеме и проверяется по структуре и ограничениям; ученик может изменить или удалить пункты, а сохранение под выбранной темой происходит только после явного подтверждения. Автоматического сохранения нет. Это реализованный процесс подготовки предложения, а не генератор проверенного курса: цитаты и научные утверждения всё ещё требуют ручной проверки, а ручная приёмка на Mac не завершена.

### Practice and feedback / Практика и обратная связь

Make practice varied and meaningful. Randomize answer positions in multiple-choice tasks while preserving the correct mapping for the whole attempt; avoid repeated positional patterns across a question set where practical. Use plausible distractors. Explain why both correct and incorrect responses are right or wrong, and offer a useful next action. Include interactive tasks and free-response formats, not only multiple-choice quizzes.

Делай практику разнообразной и содержательной. Перемешивай позиции вариантов в тестах, сохраняя правильное соответствие в течение попытки; по возможности избегай повторяющегося шаблона позиций в серии вопросов. Используй правдоподобные отвлекающие варианты. Объясняй, почему верный ответ верен, а ошибочный — нет, и предлагай полезный следующий шаг. Используй интерактивные задания и свободные ответы, а не только тесты с выбором варианта.

Record attempts, hints, optional self-reported error categories, and activity evidence separately from lesson completion and mastery claims. Preserve retry feedback, progress, and due reviews. Never turn self-report into a diagnosis or present an unvalidated score as a learner's true mastery.

Храни попытки, подсказки, необязательную самооценку типа ошибки и результаты интерактивов отдельно от завершения урока и утверждений об освоении. Сохраняй обратную связь при повторе, прогресс и сроки повторений. Не превращай самооценку в диагноз и не выдавай непроверенную оценку за настоящий уровень знаний ученика.

### Visual and interactive learning / Наглядное и интерактивное обучение

Give most core learning topics a purposeful visual or interactive companion where it genuinely improves understanding. Choose a diagram, graph, animation, experiment, simulation, video, or interactive 3D model to fit the concept. Let learners rotate or zoom models, inspect parts, reveal or hide layers, change meaningful parameters, observe results, and make a prediction before seeing an explanation. Track which topics have a working visual, its source and limitations, and which still need one; do not count placeholders as coverage.

Для большинства основных учебных тем создавай осмысленное визуальное или интерактивное сопровождение, если оно действительно помогает пониманию. Подбирай схему, график, анимацию, эксперимент, симуляцию, видео или интерактивную 3D-модель под конкретное понятие. Давай ученику вращать и приближать модель, рассматривать детали, открывать и скрывать слои, менять осмысленные параметры, наблюдать результат и делать прогноз до объяснения. Отмечай, для каких тем уже есть рабочая визуализация, каковы её источник и ограничения, а где её ещё нет; заглушки не считаются покрытием.

Every visual should teach something: identify its controls, observable outcomes, assumptions, and limits. Do not add 3D or motion only for decoration. Keep a clear text explanation, keyboard-accessible controls, reduced-motion behavior, and useful labels available alongside visual interaction.

Каждая визуализация должна чему-то учить: указывай элементы управления, наблюдаемые результаты, допущения и ограничения. Не добавляй 3D или анимацию только ради украшения. Вместе с визуальным взаимодействием сохраняй понятное текстовое объяснение, управление с клавиатуры, поддержку уменьшения анимации и доступные подписи.

### Content, sources, and RAG / Материалы, источники и RAG

Build lessons from the latest suitable official or primary sources that can be reviewed. Show the organization or author, title, source link, publication or revision date when available, last checked date, and review state. Distinguish established facts from hypotheses, uncertainty, and interpretation. Do not invent citations, research, or claims of freshness.

Создавай уроки по самым новым подходящим официальным или первичным источникам, которые можно проверить. Показывай организацию или автора, название и ссылку на источник, дату публикации или редакции при наличии, дату последней проверки и статус ревью. Разделяй установленный факт, гипотезу, неопределённость и интерпретацию. Не выдумывай ссылки, исследования и заявления об актуальности.

Use RAG to retrieve relevant approved material and cite it in context. Monitor supported sources only within their technical and license limits. A changed page or refreshed index does not update approved lesson text automatically: send detected changes to editorial review, then record who reviewed the content and when. Keep metadata-only sources out of text retrieval unless permission and policy allow it.

Используй RAG, чтобы находить подходящие разрешённые материалы и цитировать их в контексте ответа. Отслеживай источники только в пределах технических и лицензионных ограничений. Изменение страницы или обновление индекса не должно автоматически переписывать утверждённый текст урока: передавай найденные изменения на редакторскую проверку, затем сохраняй, кто и когда проверил содержание. Источники в режиме metadata-only не добавляй в текстовый поиск без разрешения и подходящей политики.

### AI architecture and routes / Архитектура ИИ и маршруты

Build a hybrid online/offline architecture. Use a coordinator to plan and synthesize an answer, with specialist roles for suitable subjects and review tasks. Provide configurable provider and model routes per role, including draft, critic, verifier, subject expert, and final answer. Coordinate agents through explicit inputs and outputs, and show the learner one coherent final answer with appropriate citations.

Построй гибридную онлайн-/офлайн-архитектуру. Используй координатора для планирования и сборки ответа, а для подходящих предметов и проверок — роли специалистов. Дай возможность настраивать провайдера и модель отдельно для каждой роли: черновик, критик, проверяющий, предметный эксперт и итоговый ответ. Связывай агентов через явные входы и результаты, а ученику показывай один цельный итоговый ответ с подходящими источниками.

Support local Ollama models for offline work and user-configured OpenAI-compatible APIs for online work. Keep a clearly discoverable Local Models screen with service availability, installed models, selected model, role assignments, refresh, and a real-response check. Keep provider and model configuration in the Control Center. Use free-only routes by default; quotas and model availability can change. Block potentially paid routes until the user explicitly enables them, and explain when learner context leaves the device. Store provider secrets in macOS Keychain, never in source code or Git.

Поддерживай локальные модели Ollama для работы без сети и настроенные пользователем OpenAI-совместимые API для онлайн-режима. Сделай легко находимый экран «Локальные модели» с доступностью сервиса, установленными моделями, выбранной моделью, назначением ролей, обновлением списка и проверкой реального ответа. Настройки провайдеров и моделей размещай в Центре управления. По умолчанию используй только бесплатные маршруты; квоты и доступность моделей могут меняться. Блокируй потенциально платные маршруты, пока пользователь явно их не разрешит, и сообщай, когда контекст ученика покидает устройство. Храни секреты провайдеров в macOS Keychain, никогда не добавляй их в исходный код или Git.

Keep health states separate: a responding local backend is not proof that Ollama is running, a model is installed, a route is configured, or a model has returned a useful answer. Show the failing layer and actionable recovery steps. Never report orchestration success when a required agent or final synthesis failed.

Разделяй состояния готовности: ответ локального backend не доказывает, что работает Ollama, установлена модель, настроен маршрут или модель вернула полезный ответ. Показывай слой, на котором произошёл сбой, и конкретные способы восстановления. Не сообщай об успешной оркестрации, если обязательный агент или итоговый синтез не завершился.

### Control Center and integrations / Центр управления и интеграции

Build an administration and diagnostic area for courses, learner-created material, source status, RAG indexing, provider and model routes, local models, usage, backend health, and errors. Distinguish structure checks from fact checks. Do not include API keys, chat messages, or private notes in diagnostic exports unless the learner explicitly chooses to export them.

Создай административный и диагностический раздел для курсов, материалов ученика, статусов источников, индекса RAG, маршрутов провайдеров и моделей, локальных моделей, использования, состояния backend и ошибок. Разделяй проверку структуры и проверку фактов. Не включай API-ключи, переписки и личные заметки в диагностические файлы, если ученик явно не выбрал их экспорт.

Support an optional Obsidian connection with clear permissions and source attribution. For personal NotebookLM, use only workflows documented by official sources; where automatic API access is unavailable, provide a clear Markdown export/import workflow and do not claim background sync.

Поддерживай необязательное подключение Obsidian с понятными разрешениями и указанием источника. Для личного NotebookLM используй только способы, подтверждённые официальными источниками; если автоматический API недоступен, предложи понятный экспорт/импорт Markdown и не заявляй о фоновой синхронизации.

### macOS product design / Дизайн приложения для macOS

Use native SwiftUI and Apple Human Interface Guidelines. Build a calm, distinctive, polished learning workspace with clear hierarchy, readable content, deliberate spacing, native navigation, keyboard support, accessibility, and recovery from errors. Avoid generic neon styling, a chat-first layout, fake buttons, placeholder screens, and status labels that overstate what works.

Используй нативный SwiftUI и рекомендации Apple Human Interface Guidelines. Создай спокойное, выразительное и аккуратное рабочее пространство для обучения с ясной иерархией, читаемым содержанием, продуманными отступами, нативной навигацией, управлением с клавиатуры, доступностью и восстановлением после ошибок. Избегай шаблонного неона, интерфейса вокруг одного чата, фиктивных кнопок, пустых экранов и статусов, преувеличивающих готовность.

Keep the main learning path simple: choose a subject, see progress, resume, open a topic, use its practice or visualization, receive feedback, and understand the next step. Preserve existing workflows that learners already find useful, including Continue learning and progress display, unless a verified defect requires changing them.

Сохраняй простой основной маршрут: выбрать предмет, увидеть прогресс, продолжить обучение, открыть тему, выполнить практику или исследовать визуализацию, получить обратную связь и понять следующий шаг. Сохраняй уже полезные ученикам сценарии, включая «Продолжить обучение» и отображение прогресса, если только подтверждённый дефект не требует их изменить.

### Development order and acceptance / Порядок разработки и приёмка

First audit the repository, instructions, architecture, current branch, test setup, and working tree. Record the evidence for each issue. Prioritize P0 failures—broken tutor routes, dead navigation, missing material, false status—before content expansion and visual polish. Implement one coherent, reviewable slice at a time, with focused tests and end-to-end checks that exercise the responsible layers.

Сначала проверь репозиторий, его инструкции, архитектуру, текущую ветку, систему проверок и незакоммиченные файлы. Для каждой проблемы зафиксируй факты. Сначала исправляй P0-дефекты — неработающие маршруты тьютора, сломанную навигацию, отсутствующие материалы и ложные статусы, — затем расширяй курсы и полируй визуальную часть. Делай по одному цельному, проверяемому срезу за раз, добавляя прицельные тесты и сквозные проверки нужных уровней.

Check the complete route from subject and roadmap to lesson, activity, feedback, saved progress, and recommendation. Include built-in and learner-created subjects. Verify Russian and English content. Test AI routing with mocks in CI, and run a real provider request only when the user initiates it and understands the possible quota or cost. Separate unit checks, CI builds, packaged-backend checks, live-model checks, and hands-on Mac acceptance in all reports.

Проверяй полный маршрут от предмета и карты тем до урока, упражнения, обратной связи, сохранённого прогресса и рекомендации. Охватывай встроенные и созданные учеником предметы. Проверяй русский и английский контент. В CI проверяй маршрутизацию ИИ на заглушках; реальный запрос к провайдеру запускай только по действию пользователя, который понимает возможный расход квоты или денег. В каждом отчёте отдельно указывай результаты модульных проверок, сборок CI, проверок упакованного backend, запросов к реальной модели и ручной приёмки на Mac.

Treat the current app as an early prototype until the critical routes and target-Mac behavior have been accepted. Do not promise “bug free,” complete curriculum coverage, automatically current lessons, free quotas, or a delivery date without evidence. Keep Windows and a public installer website as later work after a stable macOS release.

Считай приложение ранним прототипом, пока не приняты критичные маршруты и поведение на целевом Mac. Не обещай отсутствие багов, полноту учебной программы, автоматическую актуальность уроков, бесплатные квоты или срок выпуска без подтверждений. Приложение для Windows и публичный сайт с установщиками оставь на этап после стабильного релиза macOS.

---

## Expected working style / Ожидаемый порядок работы

Summarize the audit findings and the highest-priority next slice, then implement it. Keep project documentation bilingual: every explanatory English passage must have a complete Russian translation beside it. Keep identifiers, code, commands, model IDs, and API names unchanged. Report what changed, what was verified, what still needs a real Mac or provider, and link the exact build or pull request. Never call a planned feature complete.

Сначала кратко сообщи результаты аудита и следующий приоритетный срез, затем реализуй его. Веди документацию проекта на двух языках: рядом с каждым пояснительным текстом на английском должен быть полный русский перевод. Идентификаторы, код, команды, ID моделей и имена API оставляй без изменений. В отчёте укажи, что изменено, что проверено, для чего ещё нужен реальный Mac или провайдер, и добавь ссылку на конкретную сборку или pull request. Не называй запланированную функцию готовой.

# ColiDev — профиль продукта / ColiDev — Product Profile

> **RU:** Этот документ описывает цель продукта, требования команды и текущее состояние прототипа. Требование в профиле не означает, что функция уже реализована или проверена на Mac.
>
> **EN:** This document describes the product goal, team requirements, and current prototype status. A requirement in this profile does not mean that the feature is already implemented or verified on a Mac.

## 1. Цель продукта / Product goal

**RU:** ColiDev — нативная образовательная платформа для macOS с локальной службой и ИИ-тьютором. Она должна объединить учебные курсы, практику, персональный учебный план, визуальные тренажёры, проверяемые источники и сохранение прогресса. Это не просто чат с моделью и не набор красивых экранов: интерфейс, учебная логика, материалы, ИИ и обратная связь должны работать как единая система.

**EN:** ColiDev is a native macOS learning platform with a local service and an AI tutor. It brings together courses, practice, a personalized study plan, visual activities, reviewable sources, and saved progress. It is not just a model chat or a set of attractive screens: the interface, learning logic, materials, AI, and feedback must work as one system.

**RU:** Долгосрочная цель — помогать человеку непрерывно осваивать новые области, глубоко понимать идеи, связывать знания между дисциплинами и развивать самостоятельное мышление. Это система обучения на всю жизнь, а не фиксированный набор курсов с искусственным потолком. Продвижение должно опираться на реальные объяснения, задачи, перенос знаний и повторение; количество экранов и уроков само по себе не является результатом.

**EN:** The long-term goal is to help a learner keep exploring new fields, understand ideas deeply, connect knowledge across disciplines, and develop independent reasoning. This is a lifelong learning system, not a fixed course bundle with an artificial ceiling. Progress should rely on explanations, problems, transfer, and review; the number of screens or lessons is not an outcome by itself.

**RU:** Сейчас ColiDev — ранний командный прототип. Успешная CI-сборка подтверждает компиляцию и автоматические проверки, но сама по себе не подтверждает, что все экраны удобно работают на Mac, выбранная модель отвечает или весь каталог курсов полон. XGENT — отдельный проект и не входит в ColiDev.

**EN:** ColiDev is currently an early team prototype. A successful CI build confirms compilation and automated checks, but does not by itself confirm that every screen works well on a Mac, that the selected model responds, or that the course catalog is complete. XGENT is a separate project and is outside ColiDev.

## 2. Предметы, языки и пользовательский каталог / Subjects, languages, and learner-created content

**RU:** Основные встроенные направления: математика, английский язык, физика, биология, зоология и программирование. Биология уже входит в каталог и должна оставаться доступной; её не нужно создавать заново. Ученик также должен иметь возможность самостоятельно создавать новые предметы, добавлять темы и подтемы, а также добавлять темы в любой существующий предмет.

**EN:** The core built-in subjects are mathematics, English, physics, biology, zoology, and programming. Biology is already in the catalog and must remain available; it should not be recreated. Learners must also be able to create subjects, add topics and subtopics, and add topics to any existing subject.

**RU:** В каталоге предметов и на карте тем нужен понятный способ «+» для добавления предмета, темы или подтемы. Ученик задаёт название и описание на русском и английском, выбирает родительский предмет или тему и может отредактировать либо удалить созданное. Добавление темы в биологию не создаёт вторую биологию. Предложенный ИИ план остаётся черновиком до просмотра и явного подтверждения ученика.

**EN:** The subject catalog and topic map need a clear “+” action to add a subject, topic, or subtopic. Learners provide Russian and English names and descriptions, choose a parent subject or topic, and can edit or delete what they create. Adding a topic to Biology must not create a second Biology subject. An AI-generated outline remains a draft until the learner reviews and explicitly approves it.

**RU:** Интерфейс и учебные материалы нужны на русском и английском. Названия и описания пользовательских предметов и тем должны храниться на обоих языках. В уроках английского примеры сохраняются на изучаемом языке, а рядом даётся полный перевод или объяснение на другом языке, когда это нужно для понимания.

**EN:** The interface and learning materials must support Russian and English. Learner-created subjects and topics need names and descriptions in both languages. English-learning examples remain in the language being studied, with a complete translation or explanation in the other language beside them when needed for understanding.

**RU:** Авторские README, профили, планы, журналы и описания ColiDev в GitHub должны быть двуязычными: рядом с каждым пояснительным блоком на английском размещается полный перевод на русский. Имена API, модели, команд, кода и названия источников сохраняются без изменений, а их смысл объясняется по-русски.

**EN:** ColiDev-authored READMEs, profiles, plans, logs, and product descriptions on GitHub must be bilingual: place a complete Russian translation beside every explanatory English passage. Keep API names, model IDs, commands, code, and source titles unchanged, and explain their meaning in Russian.

## 3. Архитектура приложения и основные экраны / Application architecture and core screens

**RU:** ColiDev — нативное macOS-приложение, где интерфейс, учебный движок, курсы, источники, локальный backend, ИИ-маршруты, визуализации и прогресс работают как одна система. Главный экран — учебная панель: предметы и темы, «Продолжить обучение», сроки повторения, следующая рекомендация с краткой причиной, а также два раздельных показателя — завершение курса и подтверждения понимания по проверкам. Не подменяй один показатель другим.

**EN:** ColiDev is a native macOS app in which the interface, learning engine, courses, sources, local backend, AI routes, visual activities, and progress work as one system. The home screen is a learning dashboard with subjects and topics, Continue learning, due reviews, a next-step recommendation with a short reason, and two separate measures: course completion and evidence of understanding from checks. Never present one measure as the other.

**RU:** Рабочее пространство урока связывает теорию, подходящую предмету визуализацию или видео, практику, источники, обратную связь и сохранение попытки с переходом к следующему шагу. Отдельно находимый Центр управления содержит экран «Локальные модели», настройку провайдера и модели по каждой роли, статусы backend и оркестратора, курсы и пользовательский каталог, источники и очередь редакторской проверки, состояние RAG и диагностику. Ключи API хранятся в Keychain. Все переходы должны разрешать встроенные и созданные учеником темы; удалённый или недоступный материал показывает понятное состояние восстановления, а существующая тема не должна вести в пустой экран.

**EN:** The lesson workspace connects theory, a subject-appropriate visual activity or video, practice, sources, feedback, and a saved attempt to the next step. A clearly discoverable Control Center contains Local Models, per-role provider and model settings, backend and orchestrator status, built-in and learner-created courses, sources and editorial-review queue, RAG state, and diagnostics. API keys are stored in Keychain. Navigation must resolve both built-in and learner-created topics; a deleted or unavailable item needs a clear recovery state, and an existing topic must not lead to an empty screen.

## 4. Как должно строиться обучение / Learning model

**RU:** Учебный путь ведёт от необходимых основ к самостоятельному применению, новым и изменённым задачам, глубокому пониманию причин и механизмов, а затем — к продвинутому и уместному научному уровню. Не нужно требовать научной глубины для каждой темы; глубина должна соответствовать предмету, цели и подготовке ученика.

**EN:** A study path moves from necessary foundations to independent application, unfamiliar or changed problems, deep understanding of causes and mechanisms, and then to advanced and appropriate scientific work. Scientific depth is not required for every topic; depth should fit the subject, goal, and learner's preparation.

**RU:** Важная тема проверяется разными способами: ученик объясняет идею своими словами, решает обычную и изменённую задачу, обосновывает метод, находит ошибку и применяет знание в новом контексте. Чтение текста или один правильный ответ не считаются доказательством освоения.

**EN:** Important topics are checked in different ways: the learner explains the idea in their own words, solves a routine and a changed problem, justifies a method, finds an error, and applies the knowledge in a new context. Reading text or giving one correct answer is not evidence of mastery.

**RU:** Для каждой темы объясняй, что изучается, почему это важно, как и за счёт чего это работает, как части связаны, где идея применяется, какие у неё альтернативы и ограничения. Перемежай объяснение активным вспоминанием, прогнозом, задачей, сравнением методов, поиском ошибки и переносом на новую ситуацию. Значимые затруднения можно классифицировать как пробел в основе, понимании, памяти, применении, внимании, логике или выборе метода; это сигнал для следующего упражнения, а не диагноз по одному ответу.

**EN:** For each topic, explain what is being studied, why it matters, how and why it works, how its parts connect, where it applies, and what alternatives and limits it has. Alternate explanation with active recall, prediction, problem solving, method comparison, error finding, and transfer to a new situation. Meaningful difficulties may be classified as gaps in foundations, understanding, memory, application, attention, reasoning, or method choice; use them to choose the next activity, not to diagnose a learner from one answer.

**RU:** Для подходящих тем используй семь ориентиров глубины: знакомство с терминами; объяснение своими словами; типовое применение; перенос на изменённую или незнакомую задачу; понимание механизмов, связей и ограничений; продвинутый анализ; формальная или научная работа. Последний уровень нужен только там, где его оправдывают предмет и цель ученика.

**EN:** For suitable topics, use seven learning-depth milestones: familiarity with terms; explanation in one's own words; routine application; transfer to a changed or unfamiliar problem; understanding mechanisms, relationships, and limits; advanced analysis; and formal or scientific work. The final level is needed only when justified by the subject and learner's goal.

**RU:** Эффективность означает меньше потраченного впустую времени при устойчивом понимании, а не пропуск необходимых шагов. Чередуй активное вспоминание, интервальное повторение, разобранные примеры и самостоятельные задачи; постепенно повышай сложность и возвращайся к знаниям, которые хуже вспоминаются. Начинай с ясного объяснения простыми словами, затем вводи профессиональные термины по мере готовности ученика. Не считай быстрое чтение или поверхностное прохождение доказательством освоения.

**EN:** Efficiency means less wasted time while keeping understanding durable, not skipping necessary steps. Alternate active recall, spaced review, worked examples, and independent problems; increase difficulty gradually and revisit knowledge that is harder to recall. Start with a clear plain-language explanation, then introduce professional terms as the learner is ready. Do not treat fast reading or superficial coverage as evidence of mastery.

**RU:** Полезный цикл занятия может включать диагностику, короткую цель, объяснение, визуальное исследование, пример, самостоятельную практику, усложнение, обратную связь, анализ ошибок, проверку переноса и следующий шаг или повторение. Это ориентир, а не одинаковый шаблон: последовательность должна меняться по предмету и состоянию ученика.

**EN:** A useful lesson may include diagnosis, a short goal, explanation, visual exploration, an example, independent practice, increasing challenge, feedback, error analysis, a transfer check, and a next step or review. This is a guide rather than a fixed template: the sequence must adapt to the subject and learner.

**RU:** Урок не считается качественным только потому, что в нём присутствуют одинаковые блоки. Для каждой темы нужны собственная учебная цель, точное и понятное объяснение, содержательные примеры, практика, которая проверяет именно эту тему, полезный разбор ошибки и подходящие источники. В математике нужны решения, доказательства и графики; в физике — модели и причинно-следственные связи; в биологии и зоологии — структуры и процессы; в программировании — рабочий код, отладка и трассировка; в языках — практика в контексте. Не копируй формулировки и варианты ответов между уроками ради объёма.

**EN:** A lesson is not high quality merely because it contains the same repeated blocks. Each topic needs its own learning goal, accurate and clear explanation, meaningful examples, practice that checks that topic, useful error feedback, and appropriate sources. Mathematics needs worked solutions, proofs, and graphs; physics needs models and causal relationships; biology and zoology need structures and processes; programming needs working code, debugging, and tracing; languages need practice in context. Do not copy wording or answer choices between lessons just to increase volume.

## 5. Персонализация и долгосрочный прогресс / Personalization and long-term progress

**RU:** Система должна учитывать предпосылки, ответы, повторяющиеся ошибки, скорость, самостоятельность, устойчивость знаний и результаты повторения. Если ученик испытывает трудности, нужно найти конкретный пробел или изменить объяснение, пример, визуализацию либо упражнение. Если основы подтверждены, не следует бесконечно удерживать ученика на элементарных заданиях.

**EN:** The system should consider prerequisites, answers, recurring errors, pace, independence, knowledge retention, and review results. If the learner struggles, identify a specific gap or change the explanation, example, visualization, or activity. When the foundations are demonstrated, do not keep the learner on elementary tasks indefinitely.

**RU:** Рекомендация следующей темы должна объяснять, почему она подходит, какие знания использует и какие результаты позволят перейти дальше. Показывай отдельно завершение курса и свидетельства понимания; не придумывай процент мастерства, если его не подтверждают задания. Самооценка ученика — сигнал для проверки, а не диагноз.

**EN:** A next-topic recommendation should explain why it fits, which knowledge it uses, and what results would support moving on. Show course completion separately from evidence of understanding; do not invent a mastery percentage without assessment evidence. A learner's self-report is a cue to investigate, not a diagnosis.

**RU:** Значимую ошибку нужно объяснять по существу: что пошло не так, почему, как рассуждать правильнее и какое упражнение поможет закрепить способ. Подсказки должны помогать продвинуться самостоятельно; полный ответ показывается, когда он действительно нужен.

**EN:** Feedback on a meaningful error should explain what went wrong, why, how to reason more effectively, and which activity can reinforce the skill. Hints should help the learner make progress independently; reveal the full answer when it is genuinely needed.

**RU:** Показывай карту знаний: какие темы являются предпосылками, как идеи связаны между предметами и что логично изучить следующим. Цель эффективности — устойчивое понимание за разумное время: не повторять очевидное, но и не ускоряться ценой поверхностного прохождения.

**EN:** Show a knowledge map: which topics are prerequisites, how ideas connect across subjects, and what makes sense to study next. The efficiency goal is durable understanding in a reasonable amount of time: avoid repeating what is already clear without speeding through material superficially.

**RU:** Долгосрочный прогресс оценивай по конкретным свидетельствам: насколько ученик помнит материал при повторении, объясняет его своими словами, применяет в обычных и новых задачах, рассуждает самостоятельно и какие ошибки повторяет. Скорость решения учитывай там, где она важна для цели. Отделяй завершение урока или курса от подтверждённого понимания; не показывай точный общий «уровень знаний», если данных для него недостаточно.

**EN:** Assess long-term progress from concrete evidence: what the learner recalls during review, can explain in their own words, applies to routine and unfamiliar problems, reasons through independently, and tends to get wrong. Track solution speed when it matters to the goal. Separate lesson or course completion from demonstrated understanding; do not show a precise overall “knowledge level” when the evidence is insufficient.

## 6. Разные предметы — разные методы / Different subjects need different methods

**RU:** Не используй один шаблон для всех предметов. В математике нужны рассуждения, формулы, доказательства, графики и задачи; в физике — модели, эксперименты, симуляции и причинно-следственные связи; в биологии — структуры, процессы и системы; в зоологии — механизмы, адаптации и сопоставление организмов по данным; в программировании — исполняемая практика, отладка и алгоритмы; в английском — контекстное активное использование, понимание и исправление ошибок.

**EN:** Do not use one template for every subject. Mathematics needs reasoning, formulas, proofs, graphs, and problems; physics needs models, experiments, simulations, and causal relationships; biology needs structures, processes, and systems; zoology needs mechanisms, adaptations, and evidence-based comparison of organisms; programming needs runnable practice, debugging, and algorithms; English needs active use in context, comprehension, and error correction.

## 7. Наглядность и интерактив / Visual and interactive learning

**RU:** Для большинства основных тем нужно подобрать наглядный способ, который помогает понять именно этот материал: интерактивную схему, график, анимацию, опыт, симуляцию, видео с вопросами или управляемую 3D-модель. Если полезно, ученик должен уметь вращать и приближать модель, выделять или скрывать части, наблюдать изменение процесса и менять осмысленные параметры.

**EN:** Most core topics should have a visual format that helps explain that specific material: an interactive diagram, graph, animation, experiment, simulation, video with questions, or manipulable 3D model. When useful, learners should be able to rotate and zoom a model, reveal or hide parts, observe a process change, and adjust meaningful parameters.

**RU:** Не добавляй 3D и анимацию ради эффекта. У каждого тренажёра должны быть понятные действия, наблюдаемый результат, объяснение ограничений модели и доступная текстовая альтернатива. Интерактивы должны подходить предмету и не скрывать объяснение.

**EN:** Do not add 3D or animation for effect alone. Each activity needs clear controls, an observable outcome, an explanation of the model's limits, and an accessible text alternative. Interactions must fit the subject and must not replace the explanation.

## 8. Материалы, источники и актуальность / Materials, sources, and freshness

**RU:** Для фактических и научных утверждений используй подходящие официальные или первичные источники. Показывай автора или организацию, название, ссылку, дату публикации или редакции, дату последней проверки и статус редакторской проверки, если эти данные доступны. Не выдумывай факты, источники, исследования и актуальность. Разделяй установленный факт, гипотезу, спорное положение и интерпретацию.

**EN:** Use suitable official or primary sources for factual and scientific claims. Show the author or organization, title, link, publication or revision date, last-checked date, and editorial-review status when available. Do not invent facts, sources, studies, or claims of freshness. Distinguish established facts, hypotheses, disputed claims, and interpretation.

**RU:** RAG помогает находить одобренные материалы и связывать ответ с источниками, но сам по себе не гарантирует достоверность каждого утверждения и не обновляет текст урока. Автоматическая проверка источника может обнаружить изменение и поставить задачу редактору. Переписывать утверждённый урок можно только после проверки содержания, лицензии и происхождения материала с фиксацией даты и ответственного.

**EN:** RAG helps retrieve approved materials and connect an answer to sources, but it does not by itself guarantee every claim or update lesson text. Automatic source checks may detect a change and create an editorial task. Revise an approved lesson only after reviewing the content, license, and provenance, and record the review date and responsible editor.

## 9. ИИ, локальные модели и расходы / AI, local models, and cost controls

**RU:** Архитектура должна поддерживать офлайн-режим с локальными моделями Ollama и онлайн-режим с пользовательскими OpenAI-совместимыми API. Координатор объединяет ответы; при необходимости отдельные роли — черновик, критик, проверяющий и предметные специалисты — работают по явно заданным входам и результатам. Пользователь выбирает модель и провайдера для каждой роли.

**EN:** The architecture must support offline work with local Ollama models and online work with user-configured OpenAI-compatible APIs. A coordinator synthesizes the response; when appropriate, separate draft, critic, verifier, and subject-specialist roles operate on explicit inputs and outputs. The user can choose the provider and model for each role.

**RU:** Бесплатные маршруты и локальные модели — настройки по умолчанию, но доступность и квоты провайдеров могут меняться. Потенциально платный маршрут заблокирован, пока пользователь явно его не разрешит. До отправки контекста облачной модели приложение предупреждает о передаче данных. Секреты хранятся в macOS Keychain, а не в исходниках или Git.

**EN:** Free routes and local models are the defaults, but provider availability and quotas may change. Potentially paid routes remain blocked until the user explicitly enables them. Before sending context to a cloud model, the app discloses that data will leave the device. Secrets belong in macOS Keychain, not source code or Git.

**RU:** Статусы должны различать локальный backend, службу Ollama, установленную модель, выбранный маршрут и фактический полезный ответ. Нельзя показывать «оркестратор работает», если обязательный агент или финальная сборка ответа завершились ошибкой. Для каждого сбоя показываются точная причина и понятное действие.

**EN:** Status must distinguish the local backend, Ollama service, installed model, selected route, and an actual useful response. Do not report “orchestrator working” when a required agent or final synthesis has failed. Show the precise failure and a useful next action.

## 10. Центр управления / Control Center

**RU:** Центр управления должен давать доступ к состоянию курсов и пользовательских материалов, источникам и RAG, провайдерам и моделям, локальным моделям, диагностике backend, ошибкам и использованию. Статусы доступности, индексирования, проверки фактов и редакторской готовности должны быть раздельными. Диагностический экспорт не должен включать API-ключи, чаты и личные заметки без явного выбора пользователя.

**EN:** The Control Center should provide access to course and learner-created content status, sources and RAG, providers and models, local models, backend diagnostics, errors, and usage. Availability, indexing, fact-checking, and editorial-readiness statuses must remain separate. Diagnostic exports must not include API keys, chats, or private notes unless the user explicitly selects them.

## 11. Интеграции и приватность / Integrations and privacy

**RU:** Прогресс и пользовательские материалы по возможности хранятся локально. Интеграция с Obsidian использует явно выбранные пользователем локальные заметки и сохраняет происхождение источника. Для личного NotebookLM нужно показывать только официально поддерживаемые способы; если автоматический API недоступен, использовать экспорт Markdown и ручной импорт без заявлений о синхронизации.

**EN:** Keep progress and learner-created materials local where practical. The Obsidian integration uses notes explicitly selected by the user and preserves source provenance. For personal NotebookLM, use only officially supported workflows; when an automatic API is unavailable, provide Markdown export and manual import without claiming synchronization.

## 12. Интерфейс и платформы / Interface and platforms

**RU:** Приложение должно выглядеть и вести себя как продуманный нативный продукт для macOS: спокойная иерархия, читабельность, понятная навигация, клавиатурное управление, доступность и восстанавливаемые ошибки. Главный путь: выбрать предмет, увидеть прогресс, продолжить урок, выполнить практику или визуализацию, получить обратную связь и понять следующий шаг. Сначала стабилизируется macOS-версия; Windows и сайт с готовыми установщиками — последующий этап.

**EN:** The app should feel like a considered native macOS product, with calm hierarchy, readable content, clear navigation, keyboard access, accessibility, and recoverable errors. The main path is: choose a subject, see progress, resume a lesson, complete practice or visualization, receive feedback, and understand the next step. Stabilize macOS first; Windows and a website with ready-to-install packages come later.

**RU:** Визуальное направление уточнено командой: цветовая система должна связывать математику, английский, физику, биологию, зоологию и программирование с разными хорошо различимыми акцентами; интерфейс не должен оставаться серым и безликим. Карточки предметов, прогресс и показатели Центра управления получают сдержанные цветовые градиенты и подсветку; Liquid Glass применяется к навигации и интерактивным карточкам, а длинный учебный текст остаётся на спокойных читаемых поверхностях. На macOS 26 используется SwiftUI `glassEffect`, на macOS 13–25 — системный `regularMaterial`. Короткое движение карточек при наведении отключается вместе с переходами при Reduce Motion. Звук завершения урока настраивается отдельно, выключен по умолчанию и срабатывает только при первом завершении; видимая обратная связь остаётся доступна и без звука.

**EN:** The team clarified the visual direction: mathematics, English, physics, biology, zoology, and programming each need a distinct, readable accent, and the interface should not feel gray or anonymous. Subject cards, progress, and Control Center metrics use restrained color gradients and highlights; Liquid Glass belongs on navigation and interactive cards while long-form lesson text stays on calm, readable surfaces. macOS 26 uses SwiftUI `glassEffect`; macOS 13–25 uses the system `regularMaterial` fallback. Brief hover movement is disabled with transitions when Reduce Motion is enabled. Lesson-completion sound is configurable, off by default, and plays only on the first completion; visible feedback remains available without sound.

## 13. Отзывы команды и приоритеты проверки / Team feedback and verification priorities

**RU:** Команда сообщила, что интерфейс показывал готовность оркестратора, хотя тьютор не отвечал; отдельный раздел локальных моделей было трудно найти; модуль биологии не открывался; в части тем не хватало объяснений; правильный вариант часто угадывался по позиции (обычно первый, иногда второй); материалы и упражнения казались шаблонными. Позже команда уточнила, что биология уже есть: её нельзя добавлять заново, нужно дать ученику возможность через «+» создавать собственные предметы, темы и подтемы, в том числе внутри биологии. «Продолжить обучение» и отображение прогресса команда оценила положительно — эти сценарии нужно сохранить.

**EN:** The team reported that the interface showed the orchestrator as ready even though the tutor did not answer; a separate Local Models area was difficult to find; a Biology module did not open; some topics lacked explanations; the correct answer was often guessable by its position (usually first, sometimes second); and materials and exercises felt formulaic. The team later clarified that Biology already exists: do not add it again; provide a “+” action so learners can create their own subjects, topics, and subtopics, including within Biology. The team rated Continue learning and progress display positively; preserve those workflows.

**RU:** Это пользовательские наблюдения, а не утверждение, что каждая проблема воспроизводится в текущей сборке. `/health` проверяет локальную службу и готовность маршрута, а не генерацию ответа. Отдельная проба `/chat/stream` требует непустой ответ, но прежнее расположение рядом со статусом службы облегчало неверную трактовку зелёного индикатора как подтверждения работы тьютора. Исходники и проверки подтверждают биологические материалы и маршруты; открытие экрана на Mac всё ещё требует ручной проверки. Также нужно принять экран локальных моделей, создание через «+», объяснения, качество и разнообразие уроков, распределение ответов и работу прогресса на целевом устройстве.

**EN:** These are user observations, not a claim that every issue reproduces in the current build. `/health` checks the local service and route readiness, not answer generation. A separate `/chat/stream` probe requires a non-empty reply, but its former placement beside the service status made it easy to mistake a green indicator for a working tutor. Source and route checks confirm Biology content and links; opening the screen still needs hands-on Mac review. The target device must also accept Local Models, “+” creation, explanations, lesson quality and variety, answer distribution, and saved progress.

**RU:** В текущем срезе экран проверки ответа вынесен к выбору режима, статус службы показан нейтрально, а в чате зелёный статус модели появляется только после непустого ответа. Пустой финальный ответ больше не считается успешной беседой и выводит понятную ошибку. Экран «Локальные модели» есть в навигации; биология присутствует в каталоге и проверке маршрутов. Эти исправления меняют статусы и обработку пустого ответа, но не доказывают ответ настоящей модели или ручное открытие экранов на Mac. Сборка CI и приёмка на устройстве остаются отдельными критериями.

**EN:** In this slice, the reply check is placed beside the route selector, service status is neutral, and the chat shows a green model status only after a non-empty reply. An empty final response no longer counts as a successful conversation and produces a clear error. Local Models is in navigation; Biology is present in the catalog and route checks. These changes clarify status and empty-response handling but do not prove a live model reply or hands-on screen navigation on a Mac. CI build and device acceptance remain separate criteria.

**RU:** P0 — собрать текущую ветку, на целевом Mac открыть экран локальных моделей и встроенную биологию, проверить переходы и состояния, получить настоящий ответ выбранной модели и убедиться, что «Продолжить обучение» и прогресс сохранили рабочее поведение. P1 — принять создание предмета/темы через «+», проверить объяснения, точность источников по предмету и разнообразие заданий; правильные ответы должны перемешиваться или равномерно распределяться в серии, а не иметь угадываемую постоянную позицию. P2 — расширять адаптивную диагностику и учебный план на основе подтверждённых знаний, пробелов, предпосылок и переноса; добавлять осмысленные визуализации и связывать попытки с обратной связью. P3 — постепенно расширять программу, а Windows-версию и сайт установщиков начинать после стабилизации macOS.

**EN:** P0 is to build the current branch and accept it on the target Mac: open Local Models and built-in Biology, check navigation and status messages, get a real reply from the selected model, and confirm that Continue learning and progress still work. P1 is to accept subject and topic creation through “+”, review explanations and subject-level source accuracy, and improve exercise variety; correct answers must be shuffled or balanced across a sequence rather than kept at a guessable fixed position. P2 is to expand adaptive diagnosis and study planning from demonstrated knowledge, gaps, prerequisites, and transfer; add purposeful visualizations and connect attempts to feedback. P3 is to grow the curriculum gradually and begin the Windows app and installer website after macOS is stable.

## 14. Критерий готовности / Readiness standard

**RU:** Не называть приложение готовым или работающим без доказательств. Раздельно сообщать о проверках кода, CI-сборке и упаковке, ручном прохождении экранов на Mac и реальном ответе выбранного провайдера. Формулировки «без багов», «полная программа», «уроки автоматически актуализируются» и «бесплатная модель всегда доступна» допустимы только при соответствующих подтверждениях.

**EN:** Do not call the app complete or working without evidence. Report code checks, CI build and packaging, hands-on Mac screen review, and a real reply from the selected provider separately. Claims such as “bug-free,” “complete curriculum,” “lessons update automatically,” and “a free model is always available” require evidence.

**RU:** Любую новую функцию оценивай по тому, помогает ли она ученику лучше понимать, применять и переносить знания. Сначала устраняй критические ошибки навигации, сохранения, тьютора и статусов; визуальные улучшения и расширение программы планируй после них, если они не закрывают критичный учебный сценарий.

**EN:** Evaluate every new feature by whether it helps learners understand, apply, and transfer knowledge. Fix critical problems with navigation, saving, the tutor, and status reporting first; schedule visual polish and curriculum expansion after those fixes unless they are needed to unblock a critical learning workflow.

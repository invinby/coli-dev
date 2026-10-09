# ColiDev — профиль продукта / ColiDev — Product Profile

> **RU:** Этот документ описывает цель продукта, требования команды и текущее состояние прототипа. Требование в профиле не означает, что функция уже реализована или проверена на Mac.
>
> **EN:** This document describes the product goal, team requirements, and current prototype status. A requirement in this profile does not mean that the feature is already implemented or verified on a Mac.

## 1. Цель продукта / Product goal

**RU:** ColiDev — нативная образовательная платформа для macOS с локальной службой и ИИ-тьютором. Она должна объединить учебные курсы, практику, персональный учебный план, визуальные тренажёры, проверяемые источники и сохранение прогресса. Это не просто чат с моделью и не набор красивых экранов: интерфейс, учебная логика, материалы, ИИ и обратная связь должны работать как единая система.

**EN:** ColiDev is a native macOS learning platform with a local service and an AI tutor. It brings together courses, practice, a personalized study plan, visual activities, reviewable sources, and saved progress. It is not just a model chat or a set of attractive screens: the interface, learning logic, materials, AI, and feedback must work as one system.

**RU:** Сейчас ColiDev — ранний командный прототип. Успешная CI-сборка подтверждает компиляцию и автоматические проверки, но сама по себе не подтверждает, что все экраны удобно работают на Mac, выбранная модель отвечает или весь каталог курсов полон. XGENT — отдельный проект и не входит в ColiDev.

**EN:** ColiDev is currently an early team prototype. A successful CI build confirms compilation and automated checks, but does not by itself confirm that every screen works well on a Mac, that the selected model responds, or that the course catalog is complete. XGENT is a separate project and is outside ColiDev.

## 2. Предметы, языки и пользовательский каталог / Subjects, languages, and learner-created content

**RU:** Основные встроенные направления: математика, английский язык, физика, биология, зоология и программирование. Биология уже входит в каталог и должна оставаться доступной; её не нужно создавать заново. Ученик также должен иметь возможность самостоятельно создавать новые предметы, добавлять темы и подтемы, а также добавлять темы в любой существующий предмет.

**EN:** The core built-in subjects are mathematics, English, physics, biology, zoology, and programming. Biology is already in the catalog and must remain available; it should not be recreated. Learners must also be able to create subjects, add topics and subtopics, and add topics to any existing subject.

**RU:** Интерфейс и учебные материалы нужны на русском и английском. Названия и описания пользовательских предметов и тем должны храниться на обоих языках. В уроках английского примеры сохраняются на изучаемом языке, а рядом даётся полный перевод или объяснение на другом языке, когда это нужно для понимания.

**EN:** The interface and learning materials must support Russian and English. Learner-created subjects and topics need names and descriptions in both languages. English-learning examples remain in the language being studied, with a complete translation or explanation in the other language beside them when needed for understanding.

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

**RU:** Для подходящих тем используй семь ориентиров глубины: знакомство с терминами; объяснение своими словами; типовое применение; перенос на изменённую или незнакомую задачу; понимание механизмов, связей и ограничений; продвинутый анализ; формальная или научная работа. Последний уровень нужен только там, где его оправдывают предмет и цель ученика.

**EN:** For suitable topics, use seven learning-depth milestones: familiarity with terms; explanation in one's own words; routine application; transfer to a changed or unfamiliar problem; understanding mechanisms, relationships, and limits; advanced analysis; and formal or scientific work. The final level is needed only when justified by the subject and learner's goal.

**RU:** Полезный цикл занятия может включать диагностику, короткую цель, объяснение, визуальное исследование, пример, самостоятельную практику, усложнение, обратную связь, анализ ошибок, проверку переноса и следующий шаг или повторение. Это ориентир, а не одинаковый шаблон: последовательность должна меняться по предмету и состоянию ученика.

**EN:** A useful lesson may include diagnosis, a short goal, explanation, visual exploration, an example, independent practice, increasing challenge, feedback, error analysis, a transfer check, and a next step or review. This is a guide rather than a fixed template: the sequence must adapt to the subject and learner.

## 5. Персонализация и долгосрочный прогресс / Personalization and long-term progress

**RU:** Система должна учитывать предпосылки, ответы, повторяющиеся ошибки, скорость, самостоятельность, устойчивость знаний и результаты повторения. Если ученик испытывает трудности, нужно найти конкретный пробел или изменить объяснение, пример, визуализацию либо упражнение. Если основы подтверждены, не следует бесконечно удерживать ученика на элементарных заданиях.

**EN:** The system should consider prerequisites, answers, recurring errors, pace, independence, knowledge retention, and review results. If the learner struggles, identify a specific gap or change the explanation, example, visualization, or activity. When the foundations are demonstrated, do not keep the learner on elementary tasks indefinitely.

**RU:** Рекомендация следующей темы должна объяснять, почему она подходит, какие знания использует и какие результаты позволят перейти дальше. Показывай отдельно завершение курса и свидетельства понимания; не придумывай процент мастерства, если его не подтверждают задания. Самооценка ученика — сигнал для проверки, а не диагноз.

**EN:** A next-topic recommendation should explain why it fits, which knowledge it uses, and what results would support moving on. Show course completion separately from evidence of understanding; do not invent a mastery percentage without assessment evidence. A learner's self-report is a cue to investigate, not a diagnosis.

**RU:** Значимую ошибку нужно объяснять по существу: что пошло не так, почему, как рассуждать правильнее и какое упражнение поможет закрепить способ. Подсказки должны помогать продвинуться самостоятельно; полный ответ показывается, когда он действительно нужен.

**EN:** Feedback on a meaningful error should explain what went wrong, why, how to reason more effectively, and which activity can reinforce the skill. Hints should help the learner make progress independently; reveal the full answer when it is genuinely needed.

**RU:** Показывай карту знаний: какие темы являются предпосылками, как идеи связаны между предметами и что логично изучить следующим. Цель эффективности — устойчивое понимание за разумное время: не повторять очевидное, но и не ускоряться ценой поверхностного прохождения.

**EN:** Show a knowledge map: which topics are prerequisites, how ideas connect across subjects, and what makes sense to study next. The efficiency goal is durable understanding in a reasonable amount of time: avoid repeating what is already clear without speeding through material superficially.

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

## 13. Отзывы команды и приоритеты проверки / Team feedback and verification priorities

**RU:** Команда сообщила, что интерфейс показывает готовность оркестратора, хотя тьютор не отвечает; в локальных моделях не нашёлся отдельный доступный раздел; модуль биологии не открывался; части тем не хватало объяснений; некоторые варианты ответов угадывались по позиции; отдельные материалы казались шаблонными. Сохранённые функции «Продолжить обучение» и отображение прогресса команда оценила положительно — их нужно сохранить.

**EN:** The team reported that the interface showed the orchestrator as ready even though the tutor did not answer; a separate, discoverable Local Models area could not be found; a Biology module did not open; some topics lacked explanations; answer positions could be guessed; and some materials felt formulaic. The team rated Continue learning and progress display positively; preserve those workflows.

**RU:** Это пользовательские наблюдения, а не утверждение, что все проблемы воспроизводятся в текущей сборке. Автоматическая CI-проверка подтвердила структуру 50 учебных маршрутов, но не заменяет ручное открытие разделов и получение ответа модели на Mac. Проверить локальные модели, тьютора, маршрут биологии и разнообразие позиций ответов во всех форматах практики ещё нужно на целевом устройстве.

**EN:** These are user observations, not a claim that every issue reproduces in the current build. Automated CI confirmed the structure of 50 learning routes, but it does not replace hands-on navigation or a model reply on a Mac. Local Models, the tutor, the Biology route, and answer-position variety across all practice formats still need review on the target device.

**RU:** По коду уже исправлен ложный успешный ответ при недоступном маршруте тьютора, готовность сверяется с выбранной локальной моделью, а отдельный пункт «Локальные модели» добавлен в навигацию. Проверки охватывают 50 учебных тем, включая биологию. Коммит приложения `cc3beae` прошёл GitHub Actions [37886842415](https://github.com/invinby/coli-dev/actions/runs/37886842415): backend-проверки, сборки macOS для Apple Silicon и Intel и smoke-проверку упакованного backend. Это не подтверждает реальный ответ модели или ручной проход интерфейса на Mac; эти проверки остаются открытыми.

**EN:** The code now prevents an unavailable tutor route from appearing as a successful answer, checks readiness against the selected local model, and exposes Local Models directly in navigation. Checks cover 50 learning topics, including Biology. App commit `cc3beae` passed GitHub Actions [37886842415](https://github.com/invinby/coli-dev/actions/runs/37886842415): backend checks, Apple Silicon and Intel macOS builds, and a packaged-backend smoke check. This does not confirm a live model response or hands-on interface review on a Mac; both remain open.

**RU:** Приоритет P0 теперь — принять эти маршруты на целевом Mac: открыть локальные модели и биологию, проверить статусы и получить настоящий ответ выбранной модели. Приоритет P1 — продолжать аудит объяснений, источников и разнообразия ответов во всех видах практики. P2 — расширять адаптивную диагностику, подтверждение освоения и предметные интерактивы: система уровней и пользовательские темы уже есть частично, но полной модели обучения пока нет. P3 — постепенно расширять программу, а Windows-версию и сайт установщиков начинать после стабилизации macOS.

**EN:** P0 is now hands-on acceptance of these routes on the target Mac: open Local Models and Biology, check the status messages, and receive a real reply from the selected model. P1 is to continue auditing explanations, sources, and answer-position variety across every practice type. P2 is to expand adaptive diagnosis, evidence of understanding, and subject-specific interactions: level progression and learner-created topics exist in part, but a complete learning model is not yet in place. P3 is to grow the curriculum gradually and begin the Windows app and installer website after macOS is stable.

## 14. Критерий готовности / Readiness standard

**RU:** Не называть приложение готовым или работающим без доказательств. Раздельно сообщать о проверках кода, CI-сборке и упаковке, ручном прохождении экранов на Mac и реальном ответе выбранного провайдера. Формулировки «без багов», «полная программа», «уроки автоматически актуализируются» и «бесплатная модель всегда доступна» допустимы только при соответствующих подтверждениях.

**EN:** Do not call the app complete or working without evidence. Report code checks, CI build and packaging, hands-on Mac screen review, and a real reply from the selected provider separately. Claims such as “bug-free,” “complete curriculum,” “lessons update automatically,” and “a free model is always available” require evidence.

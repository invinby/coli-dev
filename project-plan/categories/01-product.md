# 01. Продукт и границы

## Подтверждённая цель пользователя

Объединить текущий ColiDev и ранее описанную идею широкого учебного ИИ-тьютора в один полноценный продукт для macOS.

Подробное описание продукта, пользовательских требований и состояния прототипа хранится в [двуязычном профиле ColiDev](../PRODUCT_PROFILE_RU_EN.md).

The complete product description, learner requirements, and prototype status are recorded in the [bilingual ColiDev profile](../PRODUCT_PROFILE_RU_EN.md).

## Подтверждённый охват

Платформа должна с самого начала покрывать все важные направления, а не ограничиваться программированием. Важно определить понятную карту дисциплин и обеспечить стартовое содержание по каждой области; глубину материалов можно расширять постепенно. Русский и английский должны быть доступны в продукте с первого релиза.

## Глубина понимания / Depth of understanding

**RU:** Для каждой важной темы планировать независимые ступени: знакомство с терминами → объяснение своими словами → стандартное применение → перенос на изменённую задачу → понимание механизмов, связей и ограничений → углублённый анализ → формальная или научная работа там, где она уместна. Освоение проверять разными видами практики, а не одним тестом. Учитывать объяснение, решение обычной и новой задачи, ход рассуждений и способность находить ошибки. Не сводить весь предмет к неподтверждённому проценту мастерства.

**EN:** Plan independent stages for each important topic: familiarity with terms → explanation in one's own words → routine application → transfer to a changed problem → understanding mechanisms, relationships, and limits → advanced analysis → formal or scientific work where appropriate. Check learning with varied practice, not a single quiz. Consider explanations, routine and unfamiliar problems, reasoning, and the ability to find errors. Do not reduce a whole subject to an unsupported mastery percentage.

## Продуктовое направление

Платформа помогает изучать темы по курсам, понимать механизмы, практиковаться, находить пробелы и возвращаться к материалу. ИИ помогает объяснять и проверять знания; он не заменяет проверенные учебные материалы и источники. Должны быть онлайн- и офлайн-режимы.

## Уточнение по продуктовому брифу / Product brief clarification

- **RU:** Большой бриф из обсуждения описывает проектирование и разработку всего образовательного приложения — его интерфейса, архитектуры, курсов, источников, адаптивного плана, интерактивов и ИИ-инфраструктуры. Это не инструкция только для роли тьютора и не требование превратить приложение в один чат. Сам тьютор — один из компонентов платформы с отдельными правилами общения и источниками контекста.
- **EN:** The long brief from the discussion describes the design and development of the complete learning application—its interface, architecture, courses, sources, adaptive study plan, interactive activities, and AI infrastructure. It is not an instruction only for the tutor persona, and it does not ask to turn the product into a single chat. The tutor is one platform component with separate conversation rules and contextual sources.
- **RU:** Учебная система должна вести от основ к продвинутому и, где уместно, научному уровню; менять маршрут по ответам и пробелам ученика; сочетать объяснения, практику и обратную связь; и выбирать схемы, симуляции, видео или управляемые 3D-модели по пользе для конкретной темы. Пользователь может создавать предметы и темы. Проверенные первоисточники и честные статусы важнее количества уроков и декоративных эффектов.
- **EN:** The learning system should progress from foundations to advanced and, where appropriate, scientific depth; adapt the path to the learner's answers and gaps; combine explanations, practice, and feedback; and choose diagrams, simulations, video, or manipulable 3D models when they help with a specific topic. Learners can create subjects and topics. Verified primary sources and truthful status are more important than lesson count or decorative effects.
- **RU:** Эффективность означает устойчивое понимание без лишних повторов: сначала выявлять нужные предпосылки, затем сочетать активное вспоминание, практику, интервальные повторы и задачи на перенос. Не объявлять тему освоенной после чтения или одного верного ответа; углублять материал постепенно и идти к научному уровню только там, где это оправдано предметом и целью ученика.
- **EN:** Efficiency means durable understanding without unnecessary repetition: identify prerequisites, then combine active recall, practice, spaced review, and transfer problems. Do not mark a topic mastered after reading or one correct answer; deepen the material gradually and pursue scientific depth only when the discipline and learner's goal call for it.
- **RU:** Способ объяснения должен зависеть от природы предмета и результатов ученика. Если тема не даётся, менять подход и закрывать конкретный пробел; если базовые знания подтверждены, не задерживать ученика на элементарных заданиях. Для каждой рекомендации объяснять её причину и нужное свидетельство готовности.
- **EN:** Explanations should reflect the discipline and the learner's results. When a topic is difficult, change the approach and address a specific gap; when foundations are demonstrated, do not keep the learner on elementary exercises. Explain the reason for each recommendation and the evidence needed to move ahead.

## Рамка проектирования и разработки / Product design and implementation brief

- **RU:** Для проектирования приложения действуй как архитектор продукта, UX/UI-дизайнер и full-stack-разработчик. Сначала изучи прототип и его реальные маршруты, расставь приоритеты P0–P3 и исправь критические сбои до косметической полировки. Затем развивай единую платформу, где интерфейс, курсы, источники, ИИ, адаптивный учебный план, практика, визуализации и прогресс согласованы между собой.
- **EN:** For product design and implementation, act as a product architect, UX/UI designer, and full-stack developer. First inspect the prototype and its real navigation paths, rank work from P0 to P3, and fix critical failures before cosmetic polish. Then develop one platform where the interface, courses, sources, AI, adaptive study plan, practice, visualizations, and progress work together.
- **RU:** Главная панель показывает предметы, продолжение обучения, завершение курсов отдельно от свидетельств освоения знаний и следующий шаг с понятной причиной. Проверяй полный путь от предмета до урока, интерактива, обратной связи, сохранённого результата и дальнейшей рекомендации. Если нужный материал отсутствует, показывай восстановимую ошибку; не имитируй его наличие.
- **EN:** The dashboard shows subjects, Continue learning, course completion separately from evidence of mastery, and the next step with a clear reason. Check the full route from a subject through its lesson, activity, feedback, saved result, and next recommendation. If material is missing, show a recoverable error; do not pretend it exists.
- **RU:** Настройки и админ-панель должны различать состояние локального backend, Ollama, установленной модели, выбранного провайдера для роли и фактический ответ модели. Источники, RAG-индекс и сам текст урока имеют отдельные даты и статусы; изменение источника не переписывает урок автоматически.
- **EN:** Settings and the admin panel must distinguish the local backend, Ollama, an installed model, the provider selected for a role, and an actual model reply. Sources, the RAG index, and lesson text have separate dates and states; a source change must not silently rewrite a lesson.
- **RU:** Для новых предметов и тем сохраняй русское и английское название, стабильные связи и понятный учебный маршрут. Визуальную форму выбирай по механизму: схема, график, опыт, видео или 3D-сцена; у каждого элемента объясняй, что можно исследовать и где заканчивается точность модели.
- **EN:** For learner-created subjects and topics, keep Russian and English names, stable links, and a clear study path. Choose a visual format for the mechanism—a diagram, graph, experiment, video, or 3D scene—and explain what can be explored and where the model's accuracy ends.
- **RU:** Встроенная биология уже существует; её не нужно создавать повторно. Прототип позволяет создавать пользовательские предметы, темы и вложенные подтемы, а также добавлять темы во встроенные предметы. Черновой план от ИИ разбирается только по версии схемы JSON; ученик может отредактировать или удалить пункты на русском и английском, проверить заметки об источниках и явно подтвердить атомарное сохранение под текущей темой. Ответ не сохраняется автоматически. Неподтверждённые факты и ссылки по-прежнему требуют ручной проверки; ручная приёмка этого сценария на Mac остаётся открытой.
- **EN:** Built-in Biology already exists and must not be recreated. The prototype lets learners create custom subjects, topics, and nested subtopics, and add topics to built-in subjects. An AI outline is parsed only through a versioned JSON schema; learners can edit or remove items in Russian and English, review source notes, and explicitly confirm an atomic save beneath the current topic. The reply is never saved automatically. Unsupported claims and citations still need human review; hands-on Mac acceptance for this flow remains open.
- **RU:** Визуально поддерживать большую часть основных тем подходящим форматом и вести карту покрытия по предметам. Не требовать 3D там, где лучше работают график, схема, эксперимент или видео; не считать декоративную заглушку готовой визуализацией.
- **EN:** Give most core topics an appropriate visual companion and track coverage by subject. Do not require 3D where a graph, diagram, experiment, or video works better; a decorative placeholder does not count as a finished visualization.
- **RU:** Любую возможность помечай как запланированную, реализованную или проверенную только по фактическим данным. Сборка, автоматические проверки, проверка интерфейса на Mac и успешный ответ реальной модели — разные доказательства готовности.
- **EN:** Mark a capability as planned, implemented, or verified only from actual evidence. A successful build, automated checks, Mac UI review, and a real model reply are different kinds of readiness evidence.

## Подтверждённое будущее направление: Windows и установка продукта

После готового и проверенного macOS-релиза сделать Windows-версию с теми же основными возможностями обучения, RU/EN, ИИ, офлайн-режима, RAG, администрирования и работы с пользовательскими данными. Интерфейс должен соответствовать Windows, сохраняя общий продуктовый опыт и функциональный паритет.

После завершения настольных приложений подготовить сайт продукта с понятными страницами загрузки установщиков для macOS и Windows. Обычным пользователям установка не должна требовать Git или клонирования репозитория. Форматы установщиков, подпись приложений, обновления и каналы релиза — технические решения, которые ещё предстоит выбрать.

## Направления функций из обсуждения

- Курсы по Python/backend и другим важным областям.
- Русский и английский для интерфейса, учебных материалов и ответов ИИ.
- ИИ-тьютор с пониманием предмета, курса, урока и прогресса.
- Актуальные ответы через RAG по курсам, Obsidian и обновляемым источникам.
- Учебные материалы создаются на основе самых свежих доступных официальных первоисточников по теме; каждый урок показывает автора/организацию, название и ссылку источника, дату публикации или редакции при наличии, дату проверки нами и состояние обновления.
- Оркестрация главной модели, специализированных агентов и локальных моделей.
- Единая локальная админ-панель для контроля курсов, происхождения и актуальности материалов, индекса RAG, источников, моделей/агентов, подключений, использования и ошибок backend.
- Визуальное объяснение понятий, интерактивные эксперименты и подходящие 3D-сцены/дизайны.
- Работа с Obsidian и связь с NotebookLM.
- Визуально аккуратный, удобный macOS-интерфейс по принципам Apple.

## Границы

- Не включать XGENT.
- Не обещать бесплатные облачные модели с большими лимитами без подтверждения условий и надёжного запасного режима.
- Не обещать «всегда актуальные данные» без указания источника, даты и статуса синхронизации.
- «Самые свежие» означает новейшую подходящую официальную редакцию, доступную при последней проверке; при отсутствии даты/сигнала версии панель прямо показывает, что актуальность неизвестна. Изменение источника требует проверки содержимого и редакционного одобрения перед обновлением урока.
- Все важные области должны быть представлены с запуска; их глубина и порядок расширения могут различаться.

## Нужно определить

- Точный список дисциплин и минимальный уровень стартового курса в каждой.
- Как поддерживать качество RU/EN и обновлять обе языковые версии.
- Кто основной пользователь и какой первый сценарий обучения.
- Какое имя продукта используется в интерфейсе и критерии готовности первого релиза.
- Как измеряем эффективность обучения: выполненные упражнения, удержание, прогресс или другой результат.
- Определить графики перепроверки по скорости изменения и риску дисциплины, ответственных редакторов и минимальную редакционную проверку RU/EN.

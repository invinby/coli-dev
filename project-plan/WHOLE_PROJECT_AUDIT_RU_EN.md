# Аудит всего проекта Cause & Corse / ColiDev / Whole-project Cause & Corse / ColiDev audit — 2026-10-19

**Срез PR на начало аудита / PR snapshot at audit start:** head `167b378c63da738f69fa13540824d3d4b315d4cb` (`167b378`) was documentation-only after app-code commit `06ca2b93bbabb16994c529839602a1134c8ac69c` (`06ca2b9`). That docs commit was marked `[skip ci]`; GitHub reports no PR workflow run for it. This audit adds another documentation-only update and does not change app code. / На начало аудита head был `167b378c63da738f69fa13540824d3d4b315d4cb` (`167b378`), только документация после коммита приложения `06ca2b93bbabb16994c529839602a1134c8ac69c` (`06ca2b9`). Документный коммит помечен `[skip ci]`; GitHub не показывает для него PR workflow run. Этот аудит добавит ещё одно документное обновление без изменений кода приложения.<br>
**Дата проверки GitHub / GitHub check date:** 2026-10-19.<br>
**Статус / Status:** PR открыт как Draft и не влит. / The PR is open as Draft and is not merged.

## Короткий вывод / Executive summary

**RU:** ColiDev — рабочий macOS-прототип Cause & Corse, а не готовая версия всей долгосрочной системы. Код и CI подтверждают нативное приложение, локальный backend, несколько предметных курсов и тренажёров, AI-маршруты и источники/RAG. В текущей Codex-сессии свежая beta из run 39132086427 была запущена на Mac: Codex открыл урок «Статическое и скользящее трение» и непосредственно увидел карточку видео с согласием, вопросами, ссылкой и полем ответа. Фактическое воспроизведение, субтитры и сохранение ответа после перезапуска остаются непроверенными. Полный согласованный объём Cause & Corse за исходные 4–5 дней закончить реалистично нельзя; ниже отделены готовое, частично проверенное и оставшееся.

**EN:** ColiDev is a working macOS prototype of Cause & Corse, not the finished long-term system. Code and CI support a useful subset: a native app, bundled local backend, several subject courses and practice activities, AI routes, and source/RAG features. During the current Codex session, the fresh beta from run 39132086427 was launched on Mac; Codex opened the “Static and kinetic friction” lesson and directly observed the video card with consent, questions, a link, and an answer field. Actual playback, captions, and answer persistence after relaunch remain unverified. The entire agreed Cause & Corse scope cannot realistically be completed within the original four-to-five-day window; this audit separates completed, partially verified, and remaining work.

## Миссия и границы продукта / Mission and product boundaries

**RU:** Cause & Corse — долгосрочная система обучения, исследований и развития способностей, помогающая пользователю стать сильным создателем и строить сложные новые вещи. Дальние научные направления — интеллект, сознание и возможность создания жизни; это исследовательские цели, а не обещанный результат. ColiDev — текущий обучающий прототип этой системы. XGENT — отдельный проект, не часть этого репозитория и не цель этой ветки.

**EN:** Cause & Corse is a long-term learning and research system for developing the user's abilities to become a capable creator and build complex new things. Intelligence, consciousness, and the possibility of creating life are distant scientific research directions, not guaranteed outcomes. ColiDev is the current learning prototype for that system. XGENT is a separate project, outside this repository and this branch.

## PR #5: проверка состава и истории / PR #5: scope and history check

**RU:** Живые метаданные GitHub перед этим документным обновлением подтвердили: PR #5 открыт, Draft, база `main` (`1e7fbab`), head `codex/backend-handshake-20261018` (`167b378`), 224 изменённых файла, 490 коммитов, `+34,605 / -1,761`. Все 490 коммитов линейные, без merge-коммитов. Дифф сгруппирован по материалам приложения и плана: `macOS` (96 файлов), `project-plan` (52), `02_Areas` (50), `01_Projects` (23), `.github` (1), а также корневые `README.md` и `ARCH_LOG.md`. Посторонних путей XGENT или несвязанных бинарных/генерированных папок в проверенном составе нет.

**EN:** Live GitHub metadata before this documentation update confirmed PR #5 was open and Draft, based on `main` (`1e7fbab`), with head `codex/backend-handshake-20261018` (`167b378`), 224 changed files, 490 commits, and `+34,605 / -1,761`. The 490 commits are linear, with no merge commits. The diff groups into app and plan content: `macOS` (96 files), `project-plan` (52), `02_Areas` (50), `01_Projects` (23), `.github` (1), plus root `README.md` and `ARCH_LOG.md`. The inspected file set contains no XGENT paths or unrelated binary/generated directories.

**RU:** PR #5 включает всю историю другого всё ещё открытого Draft PR #4: общих коммитов 460; поверх него PR #5 добавляет 30 коммитов, затрагивающих 31 файл (`+1,612 / -90`). Значит, изменения тематически относятся к ColiDev, но PR #5 является слоистым и повторно показывает большой объём PR #4. Это ухудшает удобство ревью; саму базу PR не меняли. Быстрый поиск характерных шаблонов секретов в добавленных строках не нашёл очевидных ключей, но это не полный аудит секретов всей Git-истории.

**EN:** PR #5 contains the full history of another still-open Draft PR #4: 460 commits are shared; PR #5 adds 30 commits affecting 31 files (`+1,612 / -90`). The changes are product-related, but PR #5 is stacked and repeats the large PR #4 change set. That makes review harder; the PR base has not been changed. A quick scan for common secret patterns in added lines found no obvious keys, but this is not a full secret audit of the Git history.

**RU:** `ARCH_LOG.md` — старый журнал из прежнего этапа ColiDev, созданный 13.07.2026; упоминания Freebuff/Claude в нём не означают активные интеграции текущего приложения. Текущая оценка инструментов находится в [исследовании маршрута, ресурсов и агентов](research/learning-resources-and-agent-tools-audit-2026-10-18.md).

**EN:** `ARCH_LOG.md` is a legacy log from an earlier ColiDev phase, created on 2026-07-13; its Freebuff/Claude references do not mean those tools are active integrations in the current app. The current tool assessment is in the [learning resources and agent tools research](research/learning-resources-and-agent-tools-audit-2026-10-18.md).

## Реализовано в коде / Implemented in code

**RU:** В репозитории есть нативный SwiftUI-клиент macOS с RU/EN интерфейсом, встроенный Python backend, структурированные учебные материалы, упражнения и локальное хранение учебных данных. Есть тематические задания и интерактивные модели по математике, программированию, английскому, физике, биологии и зоологии; отдельные модели и 3D-клетка не означают, что весь углублённый курс уже готов. Текущий учебный сценарий включает объяснения, практику, обратную связь и следующий шаг.

**EN:** The repository contains a native SwiftUI macOS client with RU/EN interface, a bundled Python backend, structured learning materials, practice activities, and local learning-data storage. Topic activities and interactive models exist for mathematics, programming, English, physics, biology, and zoology; individual models and a 3D cell do not mean every advanced course is complete. Current lesson flows include explanations, practice, feedback, and a next step.

**RU:** Код содержит маршруты Ollama и OpenRouter; OpenRouter уже подключён. Настройки AI-ролей, ограничения платной маршрутизации, локальный поиск по разрешённым учебным источникам и мониторинг изменений источников реализованы в разной степени. Мониторинг обнаруживает/отмечает изменения для проверки редактором, а не гарантирует автоматическое обновление каждой темы и не переписывает уроки незаметно. В коде есть Obsidian Local REST API-поиск/связка и экспорт материалов для NotebookLM; личное подключение и сквозная приёмка на Mac ещё не доказаны.

**EN:** The code contains Ollama and OpenRouter routes; OpenRouter is already integrated. AI-role settings, paid-route restrictions, local search over approved learning sources, and source-change monitoring are implemented to varying degrees. Monitoring detects or flags changes for editorial review; it does not guarantee automatic updates to every topic or silently rewrite lessons. The code includes Obsidian Local REST API retrieval and a NotebookLM materials export; personal setup and end-to-end Mac acceptance are not yet proven.

**RU:** Встроенная видеоактивность сейчас относится к уроку о трении. В коде есть согласие перед загрузкой YouTube, вопрос до просмотра, источник Khan Academy и доступ к транскрипту, вопрос после видео и поле ответа. Это один уроковый сценарий, а не готовая видеотека или полный курс.

**EN:** The embedded video activity currently belongs to the friction lesson. The code includes consent before loading YouTube, a pre-viewing question, a Khan Academy source and transcript access, a post-video question, and an answer field. This is one lesson flow, not a complete video library or course.

## Что прошло CI / What passed CI

**RU:** Последний зелёный app-code run — [39132086427](https://github.com/invinby/coli-dev/actions/runs/39132086427) для `06ca2b9`, и именно этот коммит упакован в beta. Проверены backend checks, сборка/упаковка для macOS 15 ARM, macOS 26 ARM и macOS 26 Intel, а также UI-проверка согласия и появления WebView после согласия. Последующий PR-head `167b378` содержит только документацию и был помечен `[skip ci]`; нового запуска для него нет. В workflow часть UI-шагов пропускается на Intel; успешная сборка и smoke встроенного backend не равны проверке реального воспроизведения YouTube. CI не вызывал учебную модель для подтверждения живого AI-ответа.

Описание PR дополнительно сообщает о 600 локально пройденных backend-тестах, точечной проверке статуса API и компиляции Python. Это сведения из описания PR, не результат нового запуска в рамках этого аудита. / The PR description also reports 600 locally passing backend tests, a focused API-status check, and Python compilation. These are claims from the PR description, not results rerun during this audit.

**EN:** The latest green app-code run is [39132086427](https://github.com/invinby/coli-dev/actions/runs/39132086427) for `06ca2b9`, and that is the code packaged in the beta. Backend checks and build/package jobs passed for macOS 15 ARM, macOS 26 ARM, and macOS 26 Intel; CI also has a UI check for consent and WebView appearance after consent. The later PR tip `167b378` contains documentation only and was marked `[skip ci]`, so it has no new workflow run. Some UI steps are skipped on Intel in the workflow. A successful build and bundled-backend smoke test do not equal real YouTube playback verification. CI did not send a learner prompt to confirm a live AI answer.

## Непосредственная проверка Codex на Mac / Codex direct Mac check — 2026-10-19

**RU:** В текущей Codex-сессии beta из CI run [39132086427](https://github.com/invinby/coli-dev/actions/runs/39132086427) была запущена на Mac. Codex открыл урок «Статическое и скользящее трение» и непосредственно увидел встроенную карточку видео с согласием, вопросами, ссылкой и полем ответа. Это непосредственное наблюдение Codex на Mac, а не только сообщение пользователя и не результат проверки на Windows.

**EN:** During the current Codex session, the beta from CI run [39132086427](https://github.com/invinby/coli-dev/actions/runs/39132086427) was launched on Mac. Codex opened the “Static and kinetic friction” lesson and directly observed the embedded video card with consent, questions, a link, and an answer field. This is Codex's direct observation on Mac, not merely a user report or a Windows check.

**RU:** Пока **не проверены**: фактическое воспроизведение ролика после согласия, работа субтитров, фактическое отображение/чтение транскрипта в приложении и сохранение введённого ответа после закрытия и повторного запуска. Для этих функций отдельной проверки на Mac пока нет; их не считать выполненными.

**EN:** Still **unverified**: actual playback after consent, captions, actual transcript rendering/reading in the app, and persistence of the entered answer after closing and relaunching. There is no separate Mac check result for these functions yet; do not mark them complete.

## Последовательный учебный маршрут / Sequential learning path

**RU:** Сохранять один маршрут, а не разрозненный каталог: **математика → Python → CS50x → физика с симуляциями → биология и зоология → машинное обучение → нейронаука и когнитивистика → исследование сознания → собственные проекты**. Стартовые ресурсы из подготовленного плана: Stepik [227868 — математика](https://stepik.org/course/227868/promo), Stepik [67 — Python](https://stepik.org/course/67/promo), [CS50x](https://cs50.harvard.edu/x/), [PhET](https://phet.colorado.edu/ru/) и [GeoGebra 3D](https://www.geogebra.org/3d). Сначала давать объяснение на русском; английский вводить постепенно для терминов, документации и первоисточников. Переход к следующему этапу — через небольшую проверяемую практическую работу.

**EN:** Keep one coherent path instead of a scattered catalog: **mathematics → Python → CS50x → physics with simulations → biology and zoology → machine learning → neuroscience and cognitive science → consciousness research → personal projects**. Starting resources from the prepared plan: Stepik [227868 — mathematics](https://stepik.org/course/227868/promo), Stepik [67 — Python](https://stepik.org/course/67/promo), [CS50x](https://cs50.harvard.edu/x/), [PhET](https://phet.colorado.edu/ru/), and [GeoGebra 3D](https://www.geogebra.org/3d). Explain in Russian first, then gradually add English terms, documentation, and primary sources. Move to the next stage through a small, verifiable practical project.

## Внешние agent-инструменты / External agent tools

**RU:** OpenRouter уже закрывает облачную маршрутизацию в приложении; не создавать второй аналог. OpenCode уместен отдельно как инструмент разработки. Hermes — только ограниченный исследовательский пилот, если появится конкретная задача. OpenClaw — лишь при отдельном сценарии вроде Discord. Freebuff пока не подключать к учебному runtime. Ни один из этих четырёх инструментов не отмечать как интегрированный в приложение без реализации и отдельной проверки. Решения основаны на уже сохранённом [исследовании инструментов](research/agent-tool-integration-research-2026-10-18.md).

**EN:** OpenRouter already handles cloud routing in the app; do not create a duplicate. OpenCode fits as a separate development tool. Hermes should only be considered for a constrained research pilot if a concrete task appears. OpenClaw is relevant only for a distinct scenario such as Discord. Do not connect Freebuff to the learning runtime for now. Do not mark any of these four tools as integrated into the app without implementation and separate verification. These decisions follow the existing [tool research](research/agent-tool-integration-research-2026-10-18.md).

## Открытые пункты и срок / Remaining work and timeline

**RU:** Осталось проверить видео и сохранение ответа на Mac; реальный бесплатный/разрешённый AI-маршрут и поведение при недоступной модели; сохранение настроек и прогресса после перезапуска; настройку Obsidian; экспорт/импорт NotebookLM; качество и полноту учебных материалов для всего маршрута; доступность, ошибки и приватность RAG; доступность интерфейса и навигацию; подписание, notarization, обновления и установку для пользователей. Полный курс по всем дисциплинам, полная видеотека, интеграция с каждым внешним агентом и готовая Windows-версия не завершены.

**EN:** Remaining work includes Mac checks for playback and answer persistence; a real permitted/free AI route and unavailable-model behavior; persistence of settings and progress after relaunch; Obsidian setup; NotebookLM export/import; quality and completeness of learning materials across the path; RAG availability, error handling, and privacy; accessibility and navigation; signing, notarization, updates, and user installation. Complete courses across all disciplines, a full video library, integration with every external agent, and a finished Windows version are not complete.

**RU:** Пользовательский ориентир — максимум 4–5 дней, примерно до 22–23.10.2026. Весь дальний замысел за такой срок нереалистичен. Следующий разумный результат — довести узкий, но цельный путь «урок → видео с согласием → ответ → сохранение → продолжение», проверить его на Mac и зафиксировать оставшиеся крупные этапы без объявления их готовыми.

**EN:** The user's target is at most four to five days, approximately through 2026-10-22/23. The full long-term vision is not realistic within that window. The next useful result is to complete a narrow but coherent flow—lesson → consent-gated video → answer → persistence → resume—verify it on Mac, and keep the larger remaining stages explicit rather than calling them done.

## Итоговые статусы / Final status labels

| Область / Area | Статус | Подтверждение / Evidence |
|---|---|---|
| PR #5, состав и история / PR #5 scope and history | **Проверено / Verified** | GitHub: open Draft; 224 files, 490 commits; all inspected paths are ColiDev-related; stacked on PR #4. |
| Нативная сборка и backend / Native build and backend | **CI прошло / CI passed** | [Run 39132086427](https://github.com/invinby/coli-dev/actions/runs/39132086427), commit `06ca2b9`, platform build/package jobs. |
| Видео-карточка и согласие / Video card and consent | **Непосредственно проверено Codex на Mac / Directly observed by Codex on Mac** | In the current session, Codex launched the beta from run 39132086427, opened the friction lesson, and saw the card, consent, questions, link, and answer field. |
| Воспроизведение, captions и сохранение / Playback, captions, persistence | **Не проверено / Not verified** | No Mac result for actual playback, captions, or response after relaunch. |
| Полный учебный продукт Cause & Corse / Complete Cause & Corse learning product | **Не завершено / Not complete** | Full path, media library, integrations, distribution, and release checks remain open. |
| Hermes/OpenCode/OpenClaw/Freebuff в runtime приложения / In-app runtime integrations | **Не реализовано и не требуется сейчас / Not implemented and not currently needed** | Current research recommends separate, task-specific use; OpenRouter already exists. |

<br>

Обновляй этот аудит после новых результатов с Mac или нового CI; не переносить статус из старой сборки на новую без проверки. / Update this audit when new Mac results or CI runs arrive; do not carry an old build's status forward without verification.

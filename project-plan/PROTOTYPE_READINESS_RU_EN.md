# Статус готовности прототипа ColiDev / ColiDev prototype readiness

**Дата обновления / Updated:** 2026-10-15

**Проверенный исходный коммит / Verified source commit:** `aa6aad8`

**CI:** [запуск 38648076774](https://github.com/invinby/coli-dev/actions/runs/38648076774) — успешно / passed

**Статус:** прототип готов к внутреннему тесту на Mac; это не релизный установщик. / **Status:** prototype is ready for internal Mac testing; this is not a release installer.

## Что подтверждено / What is verified

**RU:** GitHub Actions завершил backend-проверки, новый verifier доступности панелей и все Swift-verifier’ы; собрал приложение, встроил локальный backend, прошёл smoke-проверку и аудит учебных маршрутов. Успешно завершились все четыре job: backend, macOS 15 ARM, macOS 26 ARM и macOS 26 Intel. Backend: 538 тестов прошли; остался один warning Starlette/httpx. Аудит собранного каталога подтвердил 53 связанных RU/EN-урока по шести предметам и 18 уровням. В коммите `aa6aad8` исправлено перепутанное accessibility ID обзора и панели моделей; отдельная проверка этого соответствия тоже прошла. CI подтверждает компиляцию, автоматические проверки и упаковку, но не ручную отрисовку интерфейса, реальный ответ ИИ или сохранение состояния на физическом Mac.

**EN:** GitHub Actions passed backend checks, the new pane-accessibility verifier, and all Swift verifiers; it built the app, embedded the local backend, passed the backend smoke check, and audited curriculum routes. All four jobs passed: backend, macOS 15 ARM, macOS 26 ARM, and macOS 26 Intel. The backend suite reported 538 passing tests with one Starlette/httpx warning. The packaged catalog audit confirmed 53 linked RU/EN lessons across six subjects and 18 levels. Commit `aa6aad8` corrects the mismatched accessibility IDs for Overview and Models, and the dedicated mapping check passed. CI proves compilation, automated checks, and packaging, not hands-on UI rendering, a live AI response, or state persistence on a physical Mac.

## Проверка соответствия панелей / Control Center pane mapping check

**RU:** Исправлены ID для обзора, курсов, моделей, RAG, источников и интеграций, а также ID пунктов «Центр управления» и «Локальные модели» в боковой панели. Python-verifier проверяет, что каждому ID соответствует свой экран, и что переключатель и навигация имеют стабильные ID. Он упал на прежнем коде, прошёл после исправления и теперь запускается в CI. GitHub Actions `38648076774` успешно собрал и упаковал эту версию для трёх конфигураций macOS. Verifier не открывает окно; прежний пустой экран вручную не воспроизведён, его причина не установлена.

**EN:** Stable IDs now map Overview, Courses, Models, RAG, Sources, and Integrations to their own panes; the Management and Local Models sidebar items also have stable IDs. The Python verifier checks the pane-to-ID mapping and navigation identifiers. It failed against the original code, passed after the fix, and now runs in CI. GitHub Actions run `38648076774` successfully built and packaged this version for all three macOS configurations. The verifier does not open a window; the earlier blank screen has not been reproduced manually, and its cause remains unknown.

## Скачать тестовую сборку / Download the test build

Choose the artifact that matches the Mac. These are CI archives, not a signed installer. **The app is unsigned and not notarized**, so macOS may show a Gatekeeper warning. Public distribution still needs signing and notarization.

Выбери архив под свой Mac. Это архивы из CI, а не подписанный установщик. **Приложение не подписано и не нотарифицировано**, поэтому macOS может показать предупреждение Gatekeeper. Для публичного распространения ещё нужны подпись и нотарификация.

- [macOS 15 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38648076774/artifacts/11932294675) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.
- [macOS 26 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38648076774/artifacts/11933955800) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.
- [macOS 26 Intel](https://github.com/invinby/coli-dev/actions/runs/38648076774/artifacts/11933651533) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.

## Что ещё нужно проверить на Mac / What still needs hands-on Mac acceptance

- **RU:** Запуск приложения и навигацию по предметам, картам, урокам, тренажёрам, добавленным темам и «Продолжить обучение».
- **EN:** Launch and navigation across subjects, roadmaps, lessons, practice, custom topics, and Continue learning.
- **RU:** На новой сборке вручную пройти боковую навигацию, обзор и панели моделей, курсов, RAG, источников и интеграций. Перепутанные accessibility ID исправлены, но скриншот пустого экрана не воспроизведён; нужен визуальный тест этой сборки на Mac или диагностический экспорт.
- **EN:** On the new build, manually navigate the sidebar, overview, and Models, Courses, RAG, Sources, and Integrations panes. The mismatched accessibility IDs are corrected, but the blank screenshot was not reproduced; visually test this build on a Mac or provide a diagnostics export.
- **RU:** Встроенный P2-срез цели: выбрать и сменить цель, проверить этапы только после завершённого урока и успешной самопроверки, увидеть последнее место остановки и продолжить после паузы без сброса или «долга»; проверить необязательный микростарт.
- **EN:** The integrated P2 goal slice: choose and change a goal, verify milestones only after lesson completion and a passed check, see the last stopping point, resume after a break without reset or catch-up debt, and check the optional micro-start.
- **RU:** Реальный ответ выбранной локальной Ollama-модели, ответ разрешённого облачного маршрута и понятную ошибку при недоступной модели.
- **EN:** A real reply from a selected local Ollama model, a response from an allowed cloud route, and a useful error when a model is unavailable.
- **RU:** Сохранение прогресса после закрытия и повторного запуска; работу секретов в macOS Keychain на этом Mac.
- **EN:** Progress persistence after quit/relaunch and secret handling in macOS Keychain on this Mac.
- **RU:** Сохранение урока в настроенное локальное Obsidian через Local REST API; экспорт Markdown для ручного добавления в NotebookLM. Автоматическая связь с аккаунтом NotebookLM не заявлена.
- **EN:** Saving a lesson to a configured local Obsidian instance through its Local REST API; exporting Markdown for manual import into NotebookLM. Direct account-level NotebookLM integration is not claimed.

## Актуальность источников и границы / Source freshness and limits

**RU:** Монитор проверяет разрешённые источники автоматически примерно раз в 24 часа; успешно проверенный снимок может использоваться в RAG до 48 часов. Это обновляет индексируемый снимок источника, но не переписывает редакторские уроки автоматически. Даты на сайте издателя, время последней сетевой проверки и дата редакторской проверки отображаются раздельно. Достоверность каждого нового утверждения всё ещё требует проверки содержания и ссылки.

**EN:** The monitor automatically checks approved sources about every 24 hours; a successfully checked snapshot may be used in RAG for up to 48 hours. This refreshes the retrievable source snapshot; it does not automatically rewrite authored lessons. Publisher-declared dates, the latest network check, and editorial review dates remain distinct. New claims still need content and citation review.

**RU — текущая оговорка:** Точный источник Penn State Lesson 07 добавлен в проверку метаданных/отпечатка без разрешения повторно загружать его содержание в RAG. В этом запуске прямой GET через встроенный Python-клиент в Windows завершился сетевой ошибкой; PowerShell GET той же страницы вернул HTTP 200. Поэтому успешная загрузка этой конкретной страницы штатным клиентом приложения требует отдельной проверки.

**EN — current caveat:** The exact Penn State Lesson 07 URL was added to metadata/fingerprint checks without allowing its page text to be reused in RAG. In this run, the integrated Python client in Windows returned a network error for a direct GET, while PowerShell GET returned HTTP 200. A successful fetch of this specific page through the app's normal client still needs separate verification.

## Итог / Readiness summary

**RU:** Автоматическая проверка сборки и маршрутов зелёная. Приложение можно передать команде для внутренней проверки перечисленных сценариев, но нельзя считать готовым к публичному релизу, пока не пройдены ручные проверки на Mac и не подготовлена подписанная, нотарифицированная дистрибуция.

**EN:** Automated build and route checks are green. The app can go to the team for internal testing of the listed flows, but it is not ready for public release until hands-on Mac checks pass and a signed, notarized distribution is prepared.

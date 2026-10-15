# Статус готовности прототипа ColiDev / ColiDev prototype readiness

**Дата обновления / Updated:** 2026-10-15

**Проверенный коммит приложения / Verified application commit:** `1033d8e`

**CI:** [запуск 38753835401](https://github.com/invinby/coli-dev/actions/runs/38753835401) — все четыре задания успешно завершены / all four jobs passed

**Статус:** прототип готов к внутреннему тесту на Mac; это не релизный установщик. / **Status:** prototype is ready for internal Mac testing; this is not a release installer.

## Что подтверждено / What is verified

**RU:** GitHub Actions завершил 545 backend-тестов и Control Center verifier; все три macOS job прошли Swift-verifier’ы, собрали приложение, встроили локальный backend, прошли smoke-проверку и аудит учебных маршрутов. Успешно завершились все четыре job: backend, macOS 15 ARM, macOS 26 ARM и macOS 26 Intel. При реальном пробном запросе монитор получил HTTP 200, сохранил разрешённый снимок Python в RAG, а поиск вернул официальный фрагмент с URL, лицензией и временем проверки. Также исправлено явное закрытие SQLite-соединений. Аудит каталога подтвердил 54 RU/EN-маршрута по шести предметам и 18 уровням. Sources API `/knowledge/sources` показывает расчётное время следующей проверки; уроки автоматически не переписываются и не публикуются. CI подтверждает компиляцию, автоматические проверки и упаковку, но не ручную отрисовку интерфейса, живой ответ ИИ или сохранение состояния на физическом Mac.

**EN:** GitHub Actions passed 545 backend tests and the Control Center verifier. All three macOS jobs passed their Swift verifiers, built the app, embedded the local backend, passed the backend smoke check, and audited curriculum routes. All four jobs passed: backend, macOS 15 ARM, macOS 26 ARM, and macOS 26 Intel. A live source-monitor probe returned HTTP 200, stored a licensed Python documentation snapshot in RAG, and retrieved an official excerpt with its URL, license, and check timestamp. SQLite connections now close explicitly. The packaged catalog audit confirmed 54 RU/EN routes across six subjects and 18 levels. The Sources API `/knowledge/sources` exposes the calculated next check time; lessons are not automatically rewritten or published. CI proves compilation, automated checks, and packaging, not hands-on UI rendering, a live AI reply, or state persistence on a physical Mac.

## Проверка соответствия панелей / Control Center pane mapping check

**RU:** Исправлены ID для обзора, курсов, моделей, RAG, источников и интеграций, а также ID пунктов «Центр управления» и «Локальные модели» в боковой панели. Python-verifier проверяет, что каждому ID соответствует свой экран, и что переключатель и навигация имеют стабильные ID. В CI [38736168749](https://github.com/invinby/coli-dev/actions/runs/38736168749) verifier прошёл, и приложение собрано для трёх конфигураций macOS. Verifier не открывает окно; прежний пустой экран вручную не воспроизведён, его причина не установлена.

**EN:** Stable IDs now map Overview, Courses, Models, RAG, Sources, and Integrations to their own panes; the Management and Local Models sidebar items also have stable IDs. The Python verifier checks the pane-to-ID mapping and navigation identifiers. It failed against the original code, passed after the fix, and runs in CI. In GitHub Actions run [38736168749](https://github.com/invinby/coli-dev/actions/runs/38736168749), it passed again and the app built for all three macOS configurations. The verifier does not open a window; the earlier blank screen has not been reproduced manually, and its cause remains unknown.

## Скачать тестовую сборку / Download the test build

Choose the artifact that matches the Mac. These are CI archives, not a signed installer. **The app is unsigned and not notarized**, so macOS may show a Gatekeeper warning. Public distribution still needs signing and notarization.

Выбери архив под свой Mac. Это архивы из CI, а не подписанный установщик. **Приложение не подписано и не нотарифицировано**, поэтому macOS может показать предупреждение Gatekeeper. Для публичного распространения ещё нужны подпись и нотарификация.

- [macOS 15 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38753835401/artifacts/11982512745) — доступен до 29.10.2026 14:49 UTC / available until 2026-10-29 14:49 UTC.
- [macOS 26 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38753835401/artifacts/11983345425) — доступен до 29.10.2026 14:47 UTC / available until 2026-10-29 14:47 UTC.
- [macOS 26 Intel](https://github.com/invinby/coli-dev/actions/runs/38753835401/artifacts/11982768389) — доступен до 29.10.2026 14:53 UTC / available until 2026-10-29 14:53 UTC.

## Что ещё нужно проверить на Mac / What still needs hands-on Mac acceptance

- **RU:** Запуск приложения и навигацию по предметам, картам, урокам, тренажёрам, добавленным темам и «Продолжить обучение».
- **EN:** Launch and navigation across subjects, roadmaps, lessons, practice, custom topics, and Continue learning.
- **RU:** На новой сборке вручную пройти боковую навигацию, обзор и панели моделей, курсов, RAG, источников и интеграций. Перепутанные accessibility ID исправлены, но скриншот пустого экрана не воспроизведён; нужен визуальный тест этой сборки на Mac или диагностический экспорт.
- **EN:** On the new build, manually navigate the sidebar, overview, and Models, Courses, RAG, Sources, and Integrations panes. The mismatched accessibility IDs are corrected, but the blank screenshot was not reproduced; visually test this build on a Mac or provide a diagnostics export.
- **RU:** На главной проверить, что рекомендация для повторения/ошибки переводит к тренажёру, а «Продолжить» и новый урок не прыгают через теорию.
- **EN:** On the dashboard, confirm that review/error recommendations land on the trainer while Resume and a new lesson still open at the start of the lesson.
- **RU:** Встроенный P2-срез цели: выбрать и сменить цель, проверить этапы только после завершённого урока и успешной самопроверки, увидеть последнее место остановки и продолжить после паузы без сброса или «долга»; проверить необязательный микростарт.
- **EN:** The integrated P2 goal slice: choose and change a goal, verify milestones only after lesson completion and a passed check, see the last stopping point, resume after a break without reset or catch-up debt, and check the optional micro-start.
- **RU:** Реальный ответ выбранной локальной Ollama-модели, ответ разрешённого облачного маршрута и понятную ошибку при недоступной модели.
- **EN:** A real reply from a selected local Ollama model, a response from an allowed cloud route, and a useful error when a model is unavailable.
- **RU:** Сохранение прогресса после закрытия и повторного запуска; работу секретов в macOS Keychain на этом Mac.
- **EN:** Progress persistence after quit/relaunch and secret handling in macOS Keychain on this Mac.
- **RU:** Сохранение урока в настроенное локальное Obsidian через Local REST API; экспорт Markdown для ручного добавления в NotebookLM. Автоматическая связь с аккаунтом NotebookLM не заявлена.
- **EN:** Saving a lesson to a configured local Obsidian instance through its Local REST API; exporting Markdown for manual import into NotebookLM. Direct account-level NotebookLM integration is not claimed.

## Актуальность источников и границы / Source freshness and limits

**RU:** Монитор автоматически перепроверяет разрешённые источники примерно раз в 24 часа, пока работает локальный backend; успешно проверенный снимок может использоваться в RAG до 48 часов. Он обновляет индексируемый снимок и сигнал о смене страницы, но не переписывает редакторский урок автоматически. Даты издателя, сетевой проверки и редакторской проверки отображаются отдельно. После аудита прямых адресов реестр содержит 139 точных URL при лимите 150. Три издательские ссылки на научные статьи остаются за пределами автопроверки: две DOI-ссылки перенаправляют на издателей, а полная страница JEB вернула 403 из текущего сетевого окружения; монитор сознательно не следует редиректам. Четыре урока программирования используют прямые актуальные маршруты Python `/3/builtins/` и `/3/library/sys.html`. Проверены точные доступные адреса Cambridge, Python, NHGRI, NCBI, MedlinePlus, OpenStax и NIST; содержимое страниц проверяется отдельно, свежесть не доказывает каждое утверждение. Подробнее: [билингвальный аудит](research/python-current-documentation-source-audit.md).

**EN:** The monitor rechecks approved sources about every 24 hours while the local backend is running; a successfully checked snapshot may be used in RAG for up to 48 hours. It refreshes the retrievable source snapshot and change signal, but does not rewrite authored lessons. Publisher-declared dates, network checks, and editorial review dates remain distinct. After auditing direct URLs, the registry contains 139 exact-allowlisted URLs under a limit of 150. Three publisher references to research articles remain outside automatic checks: two DOI URLs redirect to publishers, and the JEB full-text page returned 403 from the current network environment; the monitor intentionally does not follow redirects. Four programming lessons now use direct current Python routes under `/3/builtins/` and `/3/library/sys.html`. Exact Cambridge, Python, NHGRI, NCBI, MedlinePlus, OpenStax, and NIST routes were checked; page accessibility does not by itself verify each lesson claim. See the [bilingual audit](research/python-current-documentation-source-audit.md).

**RU — предыдущая сетевая оговорка (2026-10-14):** Точный источник Penn State Lesson 07 добавлен в проверку метаданных/отпечатка без разрешения повторно загружать его содержание в RAG. Тогда прямой GET через встроенный Python-клиент в Windows завершился сетевой ошибкой, а PowerShell GET той же страницы вернул HTTP 200. Успешная загрузка этой страницы штатным клиентом приложения всё ещё требует отдельной проверки.

**EN — prior network caveat (2026-10-14):** The exact Penn State Lesson 07 URL was added to metadata/fingerprint checks without allowing its page text to be reused in RAG. At that time, the integrated Python client on Windows returned a network error for a direct GET, while PowerShell GET returned HTTP 200. A successful fetch through the app's normal client still needs separate verification.

## Итог / Readiness summary

**RU:** Автоматическая проверка сборки и маршрутов зелёная. Приложение можно передать команде для внутренней проверки перечисленных сценариев, но нельзя считать готовым к публичному релизу, пока не пройдены ручные проверки на Mac и не подготовлена подписанная, нотарифицированная дистрибуция.

**EN:** Automated build and route checks are green. The app can go to the team for internal testing of the listed flows, but it is not ready for public release until hands-on Mac checks pass and a signed, notarized distribution is prepared.

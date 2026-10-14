# Статус готовности прототипа ColiDev / ColiDev prototype readiness

**Дата обновления / Updated:** 2026-10-15

**Проверенный исходный коммит / Verified source commit:** `fbf3325`

**CI:** [запуск 38580193924](https://github.com/invinby/coli-dev/actions/runs/38580193924) — успешно / passed

**Статус:** прототип готов к внутреннему тесту на Mac; это не релизный установщик. / **Status:** prototype is ready for internal Mac testing; this is not a release installer.

## Что подтверждено / What is verified

**RU:** GitHub Actions завершил backend-проверки и все Swift-verifier’ы, собрал приложение, встроил локальный backend, прошёл smoke-проверку и аудит учебных маршрутов. Успешно завершились все четыре job: backend, macOS 15 ARM, macOS 26 ARM и macOS 26 Intel. Backend: 538 тестов прошли, одно предупреждение Starlette о применении `httpx` в `TestClient`. Аудит собранного каталога подтвердил 53 связанных RU/EN-урока по шести предметам и 18 уровням. Недавние содержательные исправления: округление в геометрическом тренажёре, этапы клеточного цикла и учёт независимых экспериментальных единиц в опыте с растениями. Эти результаты подтверждают CI, но не ручную приёмку интерфейса, реального ИИ или сохранения состояния на физическом Mac.

**EN:** GitHub Actions passed backend checks and all Swift verifiers, built the app, embedded the local backend, passed the backend smoke check, and audited curriculum routes. All four jobs passed: backend, macOS 15 ARM, macOS 26 ARM, and macOS 26 Intel. The backend suite reported 538 passing tests and one Starlette warning about `httpx` usage in `TestClient`. The packaged catalog audit confirmed 53 linked RU/EN lessons across six subjects and 18 levels. Recent content/model fixes include geometry rounding feedback, cell-cycle stages, and correct independent-unit counting in the plant experiment. These results prove CI behavior, not hands-on acceptance of the UI, a live AI response, or state persistence on a physical Mac.

## Изменения рабочей копии после проверенного CI / Working-tree changes after the verified CI run

**RU:** В рабочей копии исправлено соответствие accessibility ID для шести панелей Центра управления и добавлены адресные ID двух пунктов навигации. Новая локальная проверка ожидаемо падала до исправления и прошла после него; полный локальный набор backend завершился с 538 passing и одним предупреждением зависимости, `git diff --check` прошёл. Эти изменения ещё не входят в архивы из CI `38580193924`: Xcode-сборка и структурная проверка исходников ожидают новый запуск GitHub Actions. Verifier не открывает окно и не проверяет отрисовку; причина пустой панели со старого скриншота пока не установлена.

**EN:** The working tree now corrects the accessibility-ID mapping for all six Control Center panes and adds stable IDs to two navigation items. The new local verifier failed as expected before the fix and passed afterward; the full local backend suite reported 538 passing with one dependency warning, and `git diff --check` passed. These changes are not included in the archives from CI run `38580193924`: an Xcode build and source-structure check still await a new GitHub Actions run. The verifier does not open a window or check rendering, and the cause of the earlier blank panel remains unknown.

## Скачать тестовую сборку / Download the test build

Choose the artifact that matches the Mac. These are CI archives, not a signed installer. **The app is unsigned and not notarized**, so macOS may show a Gatekeeper warning. Public distribution still needs signing and notarization.

Выбери архив под свой Mac. Это архивы из CI, а не подписанный установщик. **Приложение не подписано и не нотарифицировано**, поэтому macOS может показать предупреждение Gatekeeper. Для публичного распространения ещё нужны подпись и нотарификация.

- [macOS 15 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38580193924/artifacts/11902704477) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.
- [macOS 26 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38580193924/artifacts/11903695345) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.
- [macOS 26 Intel](https://github.com/invinby/coli-dev/actions/runs/38580193924/artifacts/11903791486) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.

## Что ещё нужно проверить на Mac / What still needs hands-on Mac acceptance

- **RU:** Запуск приложения и навигацию по предметам, картам, урокам, тренажёрам, добавленным темам и «Продолжить обучение».
- **EN:** Launch and navigation across subjects, roadmaps, lessons, practice, custom topics, and Continue learning.
- **RU:** Центр управления должен показывать обзор, а переключение разделов моделей, RAG, источников и интеграций — соответствующие панели. На присланном скриншоте раздел оказался пустым; причину нельзя подтвердить по CI. Нужна ручная проверка установленной сборки на Mac или диагностический экспорт.
- **EN:** Control Center should render its overview, and its Models, RAG, Sources, and Integrations sections should show their respective panes. A supplied screenshot showed a blank section; CI cannot confirm its cause. The installed build needs hands-on Mac review or a diagnostics export.
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

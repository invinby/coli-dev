# Статус готовности прототипа ColiDev / ColiDev prototype readiness

**Дата обновления / Updated:** 2026-10-16

**Проверенный коммит приложения / Verified application commit:** `1fa481394dfb90f394b1765069b2f8844dee6e66`

**Последний CI / Latest CI:** [запуск 38821814192](https://github.com/invinby/coli-dev/actions/runs/38821814192) — backend, UI-проверка и все три сборки macOS успешно завершены / backend, UI check, and all three macOS builds passed

**Последний опубликованный релиз / Latest published release:** [ColiDev 0.1.0 Beta 7](https://github.com/invinby/coli-dev/releases/tag/v0.1.0-beta.7). Более новые коммиты доступны во временных архивах CI ниже. / Newer commits are available in the temporary CI archives below.

**Статус:** свежая неподписанная тестовая сборка готова к приёмке на Mac. Продукт ещё не завершён; проверка живых ИИ-маршрутов, сохранения после перезапуска и интеграций на устройстве остаётся открытой. / **Status:** the newest unsigned test build is ready for Mac acceptance. The product is not complete; live AI routes, persistence after relaunch, and integrations still need device checks.

**Свежая CI-сборка / Latest CI build:** [macOS 15 Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013667669), [macOS 26 Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013303065), [macOS 26 Intel](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12014066590). Артефакты истекают 29 октября 2026 года. / Artifacts expire on 29 October 2026.

## Свежая проверенная сборка CI / Latest verified CI build

**RU:** GitHub Actions [38821814192](https://github.com/invinby/coli-dev/actions/runs/38821814192) прошёл backend-проверки и сборки/упаковки для macOS 15 ARM, macOS 26 ARM и macOS 26 Intel. В задании macOS 15 также прошла UI-проверка Центра управления: элементы «Обзор» и «Обновить» доступны для нажатия; [скриншот](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013627837) приложен как отдельный артефакт и истекает 22 октября 2026 года. Исправлено переполнение содержимого `ManagementView` за границы окна. CI подтверждает рендер этого тестового окна, но не заменяет запуск на физическом Mac и не проверяет все панели. Реальные ответы ИИ, сохранение после перезапуска и интеграции требуют отдельной приёмки.

**EN:** GitHub Actions [38821814192](https://github.com/invinby/coli-dev/actions/runs/38821814192) passed backend checks and build/packaging for macOS 15 ARM, macOS 26 ARM, and macOS 26 Intel. The macOS 15 job also passed a Control Center UI test: Overview and Refresh were hittable; the [screenshot](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013627837) is a separate artifact that expires on 22 October 2026. `ManagementView` content is now constrained to the window bounds. CI confirms rendering of this test window, but does not replace running on a physical Mac or verify every pane. Live AI replies, persistence after relaunch, and integrations need separate acceptance.

## Историческая проверка Beta 7 / Historical Beta 7 verification

**RU:** GitHub Actions [38806495328](https://github.com/invinby/coli-dev/actions/runs/38806495328) прошёл backend-проверки, Swift-verifier’ы и все три сборки macOS: macOS 15 ARM, macOS 26 ARM и macOS 26 Intel. Приложение собрано и упаковано, встроенный backend прошёл smoke-проверку, аудит учебных маршрутов выполнен. [Beta 7](https://github.com/invinby/coli-dev/releases/tag/v0.1.0-beta.7) содержит новый двуязычный урок по личным местоимениям и формам *be* с семью интерактивными вопросами, подсказками, объяснениями и сохранением попыток. Каталог включает шесть предметов; предыдущие 54 маршрута расширены новым уроком. В Beta 6 добавлена полная цепочка предпосылок учебной цели; Beta 5 озвучивает контекстные предложения системными голосами macOS UK/US, если они установлены; предпочтения формата из Beta 4 сохранены. CI не проверяет отображение на физическом Mac, реальные ответы ИИ, сохранение после перезапуска или работу интеграций. Известный пустой экран Центра управления не воспроизведён, его причина не установлена; ручная проверка остаётся открытой.

**EN:** GitHub Actions [38806495328](https://github.com/invinby/coli-dev/actions/runs/38806495328) passed backend checks, Swift verifiers, and all three macOS builds: macOS 15 ARM, macOS 26 ARM, and macOS 26 Intel. The app was built and packaged, the bundled backend passed its smoke check, and the curriculum-route audit completed. [Beta 7](https://github.com/invinby/coli-dev/releases/tag/v0.1.0-beta.7) adds a bilingual lesson on personal pronouns and forms of *be*, with seven interactive questions, hints, explanations, and recorded attempts. The catalog covers six subjects; the previous 54 routes were extended with the new lesson. Beta 6 added complete learning-goal prerequisites; Beta 5 speaks contextual prompts through installed macOS UK/US voices; Beta 4's subject-scoped format preferences remain. CI does not verify rendering on a physical Mac, live AI replies, persistence after relaunch, or integration behavior. The reported blank Control Center screen has not been reproduced, and its cause remains unknown; hands-on acceptance is still open. [Apple speech synthesis documentation](https://developer.apple.com/documentation/avfoundation/speech-synthesis) describes on-device generation.
## Проверка соответствия панелей / Control Center pane mapping check

**RU:** Исправлены ID для обзора, курсов, моделей, RAG, источников и интеграций, а также ID пунктов «Центр управления» и «Локальные модели» в боковой панели. Python-verifier проверяет, что каждому ID соответствует свой экран, и что переключатель и навигация имеют стабильные ID. В CI [38736168749](https://github.com/invinby/coli-dev/actions/runs/38736168749) verifier прошёл, и приложение собрано для трёх конфигураций macOS. Verifier не открывает окно; прежний пустой экран вручную не воспроизведён, его причина не установлена.

**EN:** Stable IDs now map Overview, Courses, Models, RAG, Sources, and Integrations to their own panes; the Management and Local Models sidebar items also have stable IDs. The Python verifier checks the pane-to-ID mapping and navigation identifiers. It failed against the original code, passed after the fix, and runs in CI. In GitHub Actions run [38736168749](https://github.com/invinby/coli-dev/actions/runs/38736168749), it passed again and the app built for all three macOS configurations. The verifier does not open a window; the earlier blank screen has not been reproduced manually, and its cause remains unknown.

## Скачать тестовую сборку / Download the test build

Выбери архив под свой Mac. Это CI-сборки, а не подписанный установщик. Приложение не подписано и не нотарифицировано, поэтому macOS может показать предупреждение Gatekeeper.

Choose the archive for your Mac. These are CI builds, not signed installers. The app is unsigned and not notarized, so macOS may show a Gatekeeper warning.

- [macOS 15 Apple Silicon test ZIP](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013667669) — expires 29 October 2026, 23:20 UTC.<br>
  [Тестовый ZIP macOS 15 Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013667669) — истекает 29 октября 2026 года в 23:20 UTC.
- [macOS 26 Apple Silicon test ZIP](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013303065) — expires 29 October 2026, 23:14 UTC.<br>
  [Тестовый ZIP macOS 26 Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12013303065) — истекает 29 октября 2026 года в 23:14 UTC.
- [macOS 26 Intel test ZIP](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12014066590) — expires 29 October 2026, 23:15 UTC.<br>
  [Тестовый ZIP macOS 26 Intel](https://github.com/invinby/coli-dev/actions/runs/38821814192/artifacts/12014066590) — истекает 29 октября 2026 года в 23:15 UTC.
- [Latest numbered release: Beta 7 / Последний нумерованный релиз: Beta 7](https://github.com/invinby/coli-dev/releases/tag/v0.1.0-beta.7)
- [Release notes / Описание Beta 7](https://github.com/invinby/coli-dev/releases/tag/v0.1.0-beta.7)

Распакуй архив, перемести `ColiDev.app` в «Программы» и запусти. При предупреждении нажми Control-кликом по приложению в Finder → «Открыть» → «Открыть». Не отключай Gatekeeper целиком.

Extract the archive, move `ColiDev.app` to Applications, and launch it. If macOS warns, Control-click the app in Finder → Open → Open. Do not disable Gatekeeper globally.
## Что ещё нужно проверить на Mac / What still needs hands-on Mac acceptance

- **RU:** Запуск приложения и навигацию по предметам, картам, урокам, тренажёрам, добавленным темам и «Продолжить обучение».
- **EN:** Launch and navigation across subjects, roadmaps, lessons, practice, custom topics, and Continue learning.
- **RU:** На новой сборке вручную пройти боковую навигацию, обзор и панели моделей, курсов, RAG, источников и интеграций. CI UI-тест проверил только «Обзор» и доступность кнопки обновления; визуальная и функциональная проверка остальных панелей на физическом Mac остаётся открытой.
- **EN:** On the new build, manually navigate the sidebar, overview, and Models, Courses, RAG, Sources, and Integrations panes. The CI UI test covered only Overview and the refresh button; visual and functional review of the other panes on a physical Mac remains open.
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
- **RU:** После трёх ответов о формате проверить в «Настройках», что показано именно однозначное предпочтение; очистить историю с подтверждением и убедиться, что подсказка тьютору исчезла. Проверить русский и английский интерфейс.
- **EN:** After three format responses, confirm Settings shows only an unambiguous preference; clear the history with confirmation and verify the tutor guidance disappears. Check both Russian and English UI.

- **RU:** В уроке об ударении прослушать все четыре предложения; проверить доступные UK/US голоса и их переключение, подпись о синтезе и поведение, если нужный голос не установлен. Сравнить с Cambridge; проверить RU/EN. Не считать этот тест оценкой речи.
- **EN:** In the word-stress lesson, play all four sentences; check available UK/US voices and switching, the synthesis disclosure, and the fallback when a voice is missing. Compare with Cambridge and check RU/EN. This feature does not assess speech.

## Актуальность источников и границы / Source freshness and limits

**RU:** Монитор автоматически перепроверяет разрешённые источники примерно раз в 24 часа, пока работает локальный backend; успешно проверенный снимок может использоваться в RAG до 48 часов. Он обновляет индексируемый снимок и сигнал о смене страницы, но не переписывает редакторский урок автоматически. Даты издателя, сетевой проверки и редакторской проверки отображаются отдельно. После аудита прямых адресов реестр содержит 139 точных URL при лимите 150. Три издательские ссылки на научные статьи остаются за пределами автопроверки: две DOI-ссылки перенаправляют на издателей, а полная страница JEB вернула 403 из текущего сетевого окружения; монитор сознательно не следует редиректам. Четыре урока программирования используют прямые актуальные маршруты Python `/3/builtins/` и `/3/library/sys.html`. Проверены точные доступные адреса Cambridge, Python, NHGRI, NCBI, MedlinePlus, OpenStax и NIST; содержимое страниц проверяется отдельно, свежесть не доказывает каждое утверждение. Подробнее: [билингвальный аудит](research/python-current-documentation-source-audit.md).

**EN:** The monitor rechecks approved sources about every 24 hours while the local backend is running; a successfully checked snapshot may be used in RAG for up to 48 hours. It refreshes the retrievable source snapshot and change signal, but does not rewrite authored lessons. Publisher-declared dates, network checks, and editorial review dates remain distinct. After auditing direct URLs, the registry contains 139 exact-allowlisted URLs under a limit of 150. Three publisher references to research articles remain outside automatic checks: two DOI URLs redirect to publishers, and the JEB full-text page returned 403 from the current network environment; the monitor intentionally does not follow redirects. Four programming lessons now use direct current Python routes under `/3/builtins/` and `/3/library/sys.html`. Exact Cambridge, Python, NHGRI, NCBI, MedlinePlus, OpenStax, and NIST routes were checked; page accessibility does not by itself verify each lesson claim. See the [bilingual audit](research/python-current-documentation-source-audit.md).

**RU:** Планировщик теперь выбирает для автоматического запроса только новые или просроченные источники: обычная проверка через 24 часа, повтор после временной сетевой ошибки/недоступности — через шесть часов. Ранее срок самой скорой ссылки запускал `check_sources()` для всего реестра, так что одна временная ошибка могла преждевременно опрашивать все страницы. Ручная проверка по-прежнему проходит по полному списку. Регрессия покрыта тестом; полный backend-набор: 559 passed; аудит маршрутов подтвердил 55 уроков. CI macOS после этой правки ещё ожидается.

**EN:** The scheduler now automatically requests only new or due sources: normal sources after 24 hours, and transient network/unavailable failures after six hours. Previously, the earliest due URL triggered `check_sources()` for the entire registry, so one transient failure could cause early requests to every page. The manual check still covers the full list. A regression test covers this behavior; the full backend suite passed (559 tests), and the route audit confirmed 55 lessons. macOS CI for this change is still pending.

**RU — предыдущая сетевая оговорка (2026-10-14):** Точный источник Penn State Lesson 07 добавлен в проверку метаданных/отпечатка без разрешения повторно загружать его содержание в RAG. Тогда прямой GET через встроенный Python-клиент в Windows завершился сетевой ошибкой, а PowerShell GET той же страницы вернул HTTP 200. Успешная загрузка этой страницы штатным клиентом приложения всё ещё требует отдельной проверки.

**EN — prior network caveat (2026-10-14):** The exact Penn State Lesson 07 URL was added to metadata/fingerprint checks without allowing its page text to be reused in RAG. At that time, the integrated Python client on Windows returned a network error for a direct GET, while PowerShell GET returned HTTP 200. A successful fetch through the app's normal client still needs separate verification.

## Итог / Readiness summary

**RU:** Автоматическая проверка сборки и маршрутов зелёная. Приложение можно передать команде для внутренней проверки перечисленных сценариев, но нельзя считать готовым к публичному релизу, пока не пройдены ручные проверки на Mac и не подготовлена подписанная, нотарифицированная дистрибуция.

**EN:** Automated build and route checks are green. The app can go to the team for internal testing of the listed flows, but it is not ready for public release until hands-on Mac checks pass and a signed, notarized distribution is prepared.

# Статус готовности прототипа ColiDev / ColiDev prototype readiness

**Дата / Date:** 2026-10-14

**Проверенный исходный коммит / Verified source commit:** `1cae760`

**CI:** [запуск 38563535782](https://github.com/invinby/coli-dev/actions/runs/38563535782) — успешно / passed

**Статус:** прототип готов к внутреннему тесту на Mac; это не релизный установщик. / **Status:** prototype is ready for internal Mac testing; this is not a release installer.

## Что подтверждено / What is verified

**RU:** GitHub Actions завершил backend-проверки и все Swift-verifier’ы, собрал приложение, встроил локальный backend, прошёл smoke-проверку и аудит учебных маршрутов. Успешно завершились все четыре job: backend, macOS 15 ARM, macOS 26 ARM и macOS 26 Intel. Аудит каталога нашёл 53 связанных урока по шести предметам и 18 уровням; локально также прошли 9 тестов маршрутов. Последний math-аудит устранил неверно непомеченное округление площади и периметра в геометрическом тренажёре и добавил прямую ссылку на теорему Пифагора.

**EN:** GitHub Actions passed backend checks and all Swift verifiers, built the app, embedded the local backend, passed the backend smoke check, and audited curriculum routes. All four jobs passed: backend, macOS 15 ARM, macOS 26 ARM, and macOS 26 Intel. The catalog audit found 53 linked lessons across six subjects and 18 levels; 9 local route tests also passed. The latest mathematics audit fixed unmarked rounding in the geometry lab and added a direct Pythagorean-theorem citation.

## Скачать тестовую сборку / Download the test build

Choose the artifact that matches the Mac. These are CI archives, not a signed installer. **The app is unsigned and not notarized**, so macOS may show a Gatekeeper warning. Public distribution still needs signing and notarization.

Выбери архив под свой Mac. Это архивы из CI, а не подписанный установщик. **Приложение не подписано и не нотарифицировано**, поэтому macOS может показать предупреждение Gatekeeper. Для публичного распространения ещё нужны подпись и нотарификация.

- [macOS 15 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38563535782/artifacts/11893775123) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.
- [macOS 26 ARM / Apple Silicon](https://github.com/invinby/coli-dev/actions/runs/38563535782/artifacts/11893114267) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.
- [macOS 26 Intel](https://github.com/invinby/coli-dev/actions/runs/38563535782/artifacts/11894400460) — available until 2026-10-28 UTC / доступен до 28.10.2026 UTC.

## Что ещё нужно проверить на Mac / What still needs hands-on Mac acceptance

- **RU:** Запуск приложения и навигацию по предметам, картам, урокам, тренажёрам, добавленным темам и «Продолжить обучение».
- **EN:** Launch and navigation across subjects, roadmaps, lessons, practice, custom topics, and Continue learning.
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

## Итог / Readiness summary

**RU:** Автоматическая проверка сборки и маршрутов зелёная. Приложение можно передать команде для внутренней проверки перечисленных сценариев, но нельзя считать готовым к публичному релизу, пока не пройдены ручные проверки на Mac и не подготовлена подписанная, нотарифицированная дистрибуция.

**EN:** Automated build and route checks are green. The app can go to the team for internal testing of the listed flows, but it is not ready for public release until hands-on Mac checks pass and a signed, notarized distribution is prepared.

# ColiDev for macOS / ColiDev для macOS

ColiDev is a native SwiftUI learning app for macOS 13 and later. It brings bilingual lessons, interactive practice, study progress, and a lesson-aware tutor into one desktop app.<br>
ColiDev — нативное учебное приложение на SwiftUI для macOS 13 и новее. В нём собраны двуязычные уроки, интерактивная практика, прогресс обучения и тьютор, который учитывает текущий урок.

The app covers six priority subjects: mathematics, English, physics, biology, zoology, and programming. Each has a Russian/English roadmap from foundations toward advanced topics. The roadmaps are outlines, and the lesson collection is still a starter set rather than a complete, academically reviewed curriculum.<br>
Приложение охватывает шесть приоритетных направлений: математику, английский язык, физику, биологию, зоологию и программирование. Для каждого есть русско-английский маршрут от основ к углублённым темам. Маршруты пока являются планами, а подборка уроков — начальной версией, не полным академически проверенным курсом.

Lessons combine explanations, worked examples, practice, self-checks, limitations, and source links. Interactive modules vary by subject; the physics section includes a small 3D one-dimensional motion experiment and a measurement-scale exercise. The learner can mark a lesson complete after choosing the correct check answer and confirming completion; local progress is saved for spaced review.<br>
В уроках соединены объяснения, разобранные примеры, практика, вопросы для самопроверки, ограничения и ссылки на источники. Интерактивные модули различаются по предметам; в физике есть небольшой 3D-эксперимент по одномерному движению и упражнение со шкалой измерений. Ученик может отметить урок пройденным после правильного ответа на проверочный вопрос и подтверждения; локальный прогресс используется для интервального повторения.

## Tutor and course search / Тьютор и поиск по курсам

The SwiftUI client connects to the local FastAPI service at `127.0.0.1:8000`. Auto routing is free-only by default. Local-only mode sends tutor requests only to an Ollama service on the same device. Paid cloud routes require a separate cost-policy setting, and the app warns before learner context can be sent to a cloud provider. Provider quotas and free-model availability are not guaranteed.<br>
Клиент SwiftUI подключается к локальному серверу FastAPI по адресу `127.0.0.1:8000`. По умолчанию маршрутизация Auto ограничена бесплатными вариантами. В локальном режиме запросы тьютора отправляются только в Ollama на этом устройстве. Для платных облачных маршрутов требуется отдельное разрешение в политике расходов; приложение предупреждает перед отправкой контекста ученика облачному провайдеру. Лимиты провайдеров и доступность бесплатных моделей не гарантируются.

The local knowledge index searches bundled course Markdown and text cheat sheets. It can show source paths, line ranges, and citation details. Source-monitor checks and editor review records identify material for review; they do not automatically rewrite lessons or verify every course fact.<br>
Локальный индекс ищет по учебным Markdown-файлам и текстовым шпаргалкам, включённым в проект. Он может показывать пути к источникам, строки и сведения для цитирования. Проверки источников и записи редакторской проверки помогают найти материалы для пересмотра, но не переписывают уроки автоматически и не проверяют каждый факт курса.

Obsidian search and note export are optional and require its local REST API. NotebookLM use is a manual workflow: export a lesson to a local Markdown file, then import it yourself. Direct NotebookLM API integration and sync are not implemented.<br>
Поиск и экспорт заметок в Obsidian доступны по желанию и требуют локального REST API. NotebookLM подключается вручную: экспортируйте урок в локальный Markdown-файл, затем импортируйте его самостоятельно. Прямое подключение к API NotebookLM и синхронизация пока не реализованы.

## Build and package / Сборка и упаковка

Open `ColiDev.xcodeproj` in Xcode on a Mac, select the `ColiDev` scheme, and run it. A regular source build expects the Python backend to be started separately. To bundle a PyInstaller backend runtime into the app, follow the root [README / главную инструкцию](../../README.md) and use `scripts/package_backend_runtime.sh`.<br>
Откройте `ColiDev.xcodeproj` в Xcode на Mac, выберите схему `ColiDev` и запустите приложение. При обычной сборке из исходников сервер Python нужно запускать отдельно. Чтобы включить runtime PyInstaller в приложение, следуйте [главной инструкции](../../README.md) и используйте `scripts/package_backend_runtime.sh`.

GitHub Actions builds separate archives for Apple Silicon and Intel, bundles the backend runtime, and checks the packaged API. The current public preview is unsigned and is intended for team testing. CI does not perform hands-on interface, keyboard, VoiceOver, Keychain, or live-provider acceptance on a physical Mac.<br>
GitHub Actions собирает отдельные архивы для Apple Silicon и Intel, добавляет серверный runtime и проверяет упакованный API. Текущая публичная сборка не подписана и предназначена для командного тестирования. CI не выполняет ручную проверку интерфейса, клавиатуры, VoiceOver, Keychain и настоящих провайдеров на физическом Mac.

The app is not a finished release. Full source-reviewed courses, automatic lesson updates, a video library, complete 3D practice across subjects, NotebookLM sync, and cross-device accounts remain future work. Check the [project plan / план проекта](../../project-plan/README.md) for the current status.<br>
Приложение ещё не готово к выпуску. Полные курсы с проверенными источниками, автоматическое обновление уроков, видеотека, полноценная 3D-практика по всем предметам, синхронизация NotebookLM и аккаунты для работы на нескольких устройствах остаются будущими этапами. Текущий статус см. в [плане проекта](../../project-plan/README.md).

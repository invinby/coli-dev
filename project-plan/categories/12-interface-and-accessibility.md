# 12. Интерфейс и доступность / Interface and accessibility

## Направление / Direction

**RU:** Это рабочее описание интерфейса ColiDev, а не заявление о готовности всего продукта. Основа — нативные паттерны macOS и спокойная редакционная структура учебного материала. Цвет помогает находить предмет и различать состояние. Liquid Glass используется в навигации и интерактивных элементах; длинный учебный текст остаётся на читаемых поверхностях. Карточки предметов и показатели Центра управления получают заметные, но сдержанные цветовые градиенты, чтобы приложение не выглядело бесцветным.

**EN:** This is a working description of the ColiDev interface, not a claim that the whole product is complete. The foundation is native macOS interaction and a calm editorial structure for learning content. Color helps identify subjects and distinguish state. Liquid Glass is used for navigation and interactive elements; long-form learning content stays on readable surfaces. Subject cards and Control Center metrics get visible but restrained color gradients so the app does not look colorless.

**RU:** На macOS 26 приложение может использовать SwiftUI `glassEffect` для контролов. Для старых поддерживаемых систем 13–25 остаётся `regularMaterial`. Целевой минимальный deployment target приложения пока macOS 13. В сборках должны проверяться обе ветви оформления: стеклянная на новом SDK и совместимая на старом.

**EN:** On macOS 26, the app can use SwiftUI `glassEffect` for controls. Supported older systems 13–25 use `regularMaterial`. The current minimum deployment target remains macOS 13. Builds must check both appearance paths: the glass path with a newer SDK and the compatibility path with the older SDK.

## Цветовые токены предметов / Subject color tokens

| Направление | Светлая тема | Тёмная тема | Роль |
|---|---:|---:|---|
| Математика / Mathematics | `#5747B8` | `#B6A8FF` | Карточки предмета, иконки и акценты действий / Subject cards, icons, and action accents |
| Английский / English | `#B64B2B` | `#FF9778` | Карточки предмета, иконки и акценты действий / Subject cards, icons, and action accents |
| Физика / Physics | `#176FAD` | `#68B9FF` | Карточки предмета, иконки и акценты действий / Subject cards, icons, and action accents |
| Биология / Biology | `#1F7652` | `#65D39B` | Карточки предмета, иконки и акценты действий / Subject cards, icons, and action accents |
| Зоология / Zoology | `#8A5E13` | `#F2BD63` | Карточки предмета, иконки и акценты действий / Subject cards, icons, and action accents |
| Программирование / Programming | `#0E6F79` | `#55D4DF` | Карточки предмета, иконки и акценты действий / Subject cards, icons, and action accents |

**RU:** Акцент предмета кодируется не только цветом: название и символ остаются рядом. Текст не размещается непосредственно на ярком акцентном цвете без отдельной проверки контраста. Светлая и тёмная темы используют раздельные значения, а системные поверхности и текст сохраняют адаптацию macOS.

**EN:** A subject accent is never the only cue: its name and symbol remain visible. Text is not placed directly on a bright accent without a separate contrast check. Light and dark appearances use distinct values while system surfaces and text continue to adapt to macOS.

## Движение и звук / Motion and sound

**RU:** Переход между разделами и вкладками Центра управления длится 180 мс и использует обычное затухание. Карточка предмета слегка поднимается при наведении; плавно анимируется и заполнение индикатора учебного прогресса. При включённом Reduce Motion эти движения и переходы отключаются; выбранный раздел и результат действия остаются явно видимыми. Анимации не скрывают начальное содержимое и не проигрываются как заставка.

**EN:** Navigation and Control Center tab transitions last 180 ms and use a simple ease-in/ease-out. Subject cards lift slightly on hover, and the study progress ring animates as it changes. When Reduce Motion is enabled, these movements and transitions are removed; the selected section and action result remain visible. Animation never hides initial content or runs as an intro sequence.

**RU:** Короткий звук завершения использует системный звук macOS и включается только явным переключателем в настройках. По умолчанию звук выключен; он проигрывается при первом сохранённом завершении урока, а не при каждом верном ответе или повторном открытии пройденной темы. В интерфейсе сохраняется текстовая/визуальная обратная связь.

**EN:** The brief completion cue uses a macOS system sound and is enabled only by an explicit Settings toggle. Sound is off by default and plays on the first saved lesson completion, not on every correct answer or when reopening an already completed topic. Text and visual feedback remain available.

## Центр управления / Control Center

**RU:** Обзор должен сразу показывать полезное содержимое даже до ответа backend: цветные показатели, состояние системы и доступные действия. Карточки показателей используют символ, метку, значение и отдельный оттенок статуса; они не должны исчезать, пока загружается backend. Главная view и вкладка обзора имеют accessibility identifiers, а контейнер обзора — минимальную высоту для проверки в detail-контейнере. Эти изменения улучшают диагностику и layout-устойчивость, но не доказывают причину пустого экрана из пользовательского скриншота. Ручная проверка на Mac остаётся обязательной.

**EN:** The overview should show useful content before the backend replies: colored metrics, system status, and available actions. Metric cards pair a symbol and label with a value and distinct status tint; they must not disappear while the backend loads. The root view and overview pane have accessibility identifiers, and the overview container has an explicit minimum height for the detail layout. These changes improve diagnosis and layout resilience but do not prove the cause of the blank screen in the team screenshot. Hands-on Mac verification is still required.

## Проверка / Acceptance

| RU | EN |
|---|---|
| Сборка на macOS 15 подтверждает совместимый `regularMaterial` fallback; macOS 26 подтверждает SwiftUI Liquid Glass API. | A macOS 15 build checks the `regularMaterial` fallback; macOS 26 checks the SwiftUI Liquid Glass API. |
| На реальном Mac открыть Центр управления, все шесть вкладок и экран локальных моделей; убедиться, что обзор не пустой при доступном и недоступном backend. | On a real Mac, open Control Center, all six panes, and Local Models; confirm that the overview is not blank with both available and unavailable backend states. |
| Проверить RU/EN, светлую/тёмную тему, клавиатуру и VoiceOver, включённый Reduce Motion, выключенный/включённый звук. | Check RU/EN, light/dark appearance, keyboard and VoiceOver, Reduce Motion enabled, and sound both off and on. |
| Не объявлять весь редизайн или продукт завершённым по одному успешному CI build или наличию SwiftUI-кода. | Do not call the full redesign or product complete based on one successful CI build or the presence of SwiftUI code. |

## Технические источники / Technical references

- SwiftUI `glassEffect`: [Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/glasseffect%28_%3Ain%3A%29). Документация определяет API эффекта, а не подтверждает отображение конкретного экрана ColiDev. / The documentation defines the effect API; it does not verify the rendering of a specific ColiDev screen.
- GitHub-hosted runner labels: [GitHub Actions runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners). CI uses the `macos-26` and `macos-26-intel` labels in addition to `macos-15`. / CI использует метки `macos-26` и `macos-26-intel` вместе с `macos-15`.

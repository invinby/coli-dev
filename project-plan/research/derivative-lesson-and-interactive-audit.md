# Derivative lesson and interactive audit / Аудит урока и тренажёра производной

**Review date / Дата проверки:** 2026-10-12  
**Lesson / Урок:** [`rates_of_change_and_derivative.md`](../../02_Areas/Mathematics/lessons/rates_of_change_and_derivative.md)  
**Scope / Объём:** Checked the Russian and English explanations, difference-quotient arithmetic, graph examples, answer key, stated limits, official references, and the SwiftUI secant/tangent controls against the lesson. / Проверены русское и английское объяснения, вычисления по разностному отношению, примеры графика, ключ ответа, указанные ограничения, официальные ссылки и соответствие элементов управления SwiftUI содержанию урока.

## Findings / Выводы

**EN:** The mathematical claims are correct. For `f(x)=x²`, the difference quotient simplifies to `2x+h` for `h≠0`, and its limit as `h→0` is `2x`; the lesson's answer `f′(2)=4`, tangent slope at `x=3` of `6`, and secant examples at `x=2` (`5` for `h=1`, `4.1` for `h=0.1`) all agree. The metre/second units for the derivative of a position function are correct. The notes about corners, cusps, discontinuities, vertical tangents, and local versus distant behavior correctly avoid implying differentiability everywhere.

**RU:** Математические утверждения верны. Для `f(x)=x²` разностное отношение при `h≠0` упрощается до `2x+h`, а предел при `h→0` равен `2x`; ответ `f′(2)=4`, наклон касательной при `x=3` — `6`, а примеры наклонов секущей при `x=2` (`5` для `h=1`, `4,1` для `h=0,1`) совпадают. Единицы метр/секунда для производной функции положения указаны правильно. Ограничения про углы, острые пики, разрывы и вертикальные касательные корректно показывают, что производная существует не везде, а вывод в точке описывает локальное, не дальнее поведение функции.

**EN:** The SwiftUI activity uses the same equations, but its controls were asymmetric: `x` could move only from `−2.5` to `0.8`, while `h` could not go below `0.2`. The point slider now covers `−2` to `2`; the positive increment ranges from `0.05` to `1` in `0.05` steps. This displays positive and negative points symmetrically, keeps the secant endpoint on the plotted interval `[-3,3]`, approaches zero more closely without ever setting `h=0`, and includes the lesson's `h=1` example. The lesson's manual source-review date is updated to `2026-10-12` after checking both cited pages.

**RU:** В SwiftUI-тренажёре использовались те же формулы, но элементы управления были несимметричными: `x` менялся только от `−2,5` до `0,8`, а `h` нельзя было уменьшить меньше `0,2`. Теперь `x` меняется от `−2` до `2`, а положительный шаг `h` — от `0,05` до `1` с шагом `0,05`. Это даёт симметричный выбор отрицательных и положительных точек, оставляет конец секущей в пределах отображаемого интервала `[-3,3]`, позволяет подойти ближе к нулю, не устанавливая `h=0`, и сохраняет пример из урока с `h=1`. Дата ручной проверки источников в уроке обновлена на `2026-10-12` после проверки обеих ссылок.

## Primary sources / Первичные источники

- OpenStax, *Calculus Volume 1*, [§3.1 Defining the Derivative](https://openstax.org/books/calculus-volume-1/pages/3-1-defining-the-derivative) — the difference quotient, tangent slope, and derivative as a limit. / OpenStax, *Calculus Volume 1*, [§3.1 «Определение производной»](https://openstax.org/books/calculus-volume-1/pages/3-1-defining-the-derivative) — разностное отношение, наклон касательной и производная как предел.
- OpenStax, *Calculus Volume 1*, [§3.2 The Derivative as a Function](https://openstax.org/books/calculus-volume-1/pages/3-2-the-derivative-as-a-function) — the derivative function's domain, differentiability, and cases where a derivative does not exist. / OpenStax, *Calculus Volume 1*, [§3.2 «Производная как функция»](https://openstax.org/books/calculus-volume-1/pages/3-2-the-derivative-as-a-function) — область определения производной, дифференцируемость и случаи, когда производная не существует.

## Verification and limits / Проверка и ограничения

**EN:** The cited pages were checked directly on 2026-10-12. The app's control ranges were inspected in source; a clean `git diff --check` and the full macOS CI build are required for this change. This review does not claim hands-on visual or accessibility acceptance on a physical Mac. The OpenStax book is CC BY-NC-SA; this lesson contains its own explanation and links, not copied textbook passages, and this audit does not grant additional reuse or RAG-ingestion rights.

**RU:** Обе официальные страницы проверены напрямую 2026-10-12. Диапазоны управления просмотрены в коде; для правки обязательны чистая проверка `git diff --check` и полный macOS CI. Этот аудит не подтверждает ручную визуальную или accessibility-приёмку на физическом Mac. Учебник OpenStax распространяется по CC BY-NC-SA; урок содержит собственное объяснение и ссылки, а не скопированные фрагменты учебника. Аудит не предоставляет дополнительных прав на повторное использование или включение текста в RAG.

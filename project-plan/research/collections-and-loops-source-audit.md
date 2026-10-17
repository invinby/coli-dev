# Collections and the `for` loop: source audit / Коллекции и цикл `for`: аудит источников

**Audit date / Дата аудита:** 2026-10-12  
**Lesson / Урок:** [`collections_and_loops.md`](../../02_Areas/Programming/lessons/collections_and_loops.md)  
**Scope / Объём:** RU/EN parity, list ordering and indexing, `append`, `for`, `enumerate`, `range`, mutation while iterating, exercise outputs, answer key, limitations, and source coverage. Claims were checked against official Python documentation only. This was a documentation/editorial review; the lesson and code were not changed or run. / Сверены версии RU/EN, порядок списка и индексы, `append`, `for`, `enumerate`, `range`, изменение списка во время обхода, вывод заданий, ключ ответа, ограничения и покрытие источниками. Утверждения сверялись только с официальной документацией Python. Это редакторская проверка по документации; урок и код не менялись и не запускались.

## Overall result / Общий результат

**EN:** The lesson is accurate at its stated introductory scope. No factual error, mismatched RU/EN rule, code-output error, or wrong answer key was found. `append()` mutates the list by adding at the end; list iteration follows sequence order; `enumerate()` pairs each value with a counter beginning at zero by default; and `range(len(items))` is unnecessary for a value-only loop. The warning about modifying a collection while traversing it and the recommendation to create a new collection for filtering match the Python tutorial. The lesson contains no Big-O or other explicit complexity claim. One small scope clarification could help: Python also accepts negative indexes, so “positions start at zero” is best read as describing the nonnegative indexes used in this lesson.

**RU:** Для заявленного вводного уровня урок точен. Фактических ошибок, расхождений правил RU/EN, ошибок в ожидаемом выводе или неправильного ключа ответа не найдено. `append()` изменяет исходный список, добавляя элемент в конец; цикл по списку сохраняет порядок последовательности; `enumerate()` связывает каждое значение со счётчиком, который по умолчанию начинается с нуля; а для обычного обхода значений `range(len(items))` не нужен. Предупреждение об изменении коллекции во время обхода и совет создавать новый список для фильтрации соответствуют руководству Python. В уроке нет утверждений о Big-O или другой явной оценке сложности. Можно добавить небольшое уточнение: Python также поддерживает отрицательные индексы, поэтому фразу «позиции считаются с нуля» здесь лучше понимать как описание неотрицательных индексов, используемых в уроке.

## Claims and examples / Утверждения и примеры

### Lists and indexing / Списки и индексация

**EN:** The statements that a list is ordered, its three-item example has nonnegative indexes `0`, `1`, and `2`, and `len(tasks)` returns `3` are correct. In Python, sequence indexing starts with origin `0`; `len()` returns the sequence length. Negative indexes also work from the end (`tasks[-1]` is the last item), but the lesson does not claim otherwise. Adding a short boundary note is optional, useful for completeness, and consistent with the stated foundations level. The statement that an index beyond the valid range raises `IndexError` is correct; the lesson appropriately says “outside the allowed range,” which includes accounting for valid negative indexes.

**RU:** Утверждения о порядке списка, индексах `0`, `1`, `2` у списка из трёх элементов и значении `len(tasks) == 3` верны. Индексация последовательностей в Python начинается с `0`, а `len()` возвращает длину последовательности. Допустимы и отрицательные индексы от конца (`tasks[-1]` — последний элемент), но урок не утверждает обратного. Короткая оговорка об этом необязательна, но будет полезна для полноты и соответствует базовому уровню курса. Утверждение, что индекс вне допустимого диапазона вызовет `IndexError`, верно; формулировка «вне допустимого диапазона» корректна с учётом допустимых отрицательных индексов.

### `append`, `for`, `enumerate`, and `range` / `append`, `for`, `enumerate` и `range`

**EN:** The example

```python
tasks = ["docs", "tests"]
tasks.append("build")
for index, task in enumerate(tasks):
    print(f"{index}: {task}")
```

prints exactly three lines: `0: docs`, `1: tests`, `2: build`. The practice list becomes `['measure', 'calculate', 'check']`, so its length is `3` and `print(index, step)` prints `0 measure`, `1 calculate`, `2 check` on separate lines. The assessment code prints `0 a`, `1 b`, `2 c` on separate lines. Markdown answer `1` means the first option in this repository's course format, and that option matches the output. The `enumerate()` explanation, iteration-order statement, and `range` recommendation are directly supported by official examples.

**RU:** Пример

```python
tasks = ["docs", "tests"]
tasks.append("build")
for index, task in enumerate(tasks):
    print(f"{index}: {task}")
```

действительно выводит три строки: `0: docs`, `1: tests`, `2: build`. После добавления в упражнении список равен `['measure', 'calculate', 'check']`, его длина — `3`, а `print(index, step)` выводит по отдельным строкам `0 measure`, `1 calculate`, `2 check`. Код проверочного вопроса печатает отдельными строками `0 a`, `1 b`, `2 c`. Ответ Markdown `1` в формате курсового парсера репозитория означает первый вариант; он совпадает с выводом. Объяснения `enumerate()`, порядка обхода и рекомендации про `range` прямо подтверждаются официальными примерами.

### Mutation during iteration / Изменение коллекции во время обхода

**EN:** The warning is sound. The official tutorial cautions that changing a collection while iterating over it is tricky and recommends iterating over a copy or creating a new collection. Python's sequence-iterator documentation also states that its index advances even if the underlying mutable sequence changes; this explains why some edits can skip values or produce surprising traversal. Building a separate list for filtering is a suitable beginner rule. No guarantee about the exact result of every kind of mutation is implied by the lesson.

**RU:** Предупреждение корректно. Официальное руководство говорит, что изменять коллекцию во время её обхода непросто и рекомендует обходить копию или создать новую коллекцию. Документация итераторов последовательностей также указывает, что их индекс продвигается, даже если исходная изменяемая последовательность меняется; поэтому некоторые изменения могут привести к пропуску значений или неожиданному обходу. Для базового урока совет фильтровать в новый список подходит. Урок не обещает один и тот же точный результат для всех возможных изменений списка.

### Assessment and limits / Проверка и ограничения

**EN:** The correct option is **1** in one-based course notation: `0 a`, `1 b`, `2 c`. Both language versions ask the same question, list options in the same order, give the same key, and explain the same behavior. “An out-of-range index raises `IndexError`” and “an empty list must not be indexed” are correct. The lesson appropriately separates its small trainer from actual code execution and timing. There is no complexity claim to validate; performance is explicitly not measured.

**RU:** Правильный вариант — **1** в принятой в курсах нумерации от единицы: `0 a`, `1 b`, `2 c`. В обеих языковых версиях одинаковые вопрос, порядок вариантов, ключ и объяснение. Утверждения «индекс вне допустимого диапазона вызывает `IndexError`» и «к пустому списку нельзя обращаться по индексу» верны. Урок правильно отделяет упрощённый тренажёр от реального запуска кода и замера времени. Проверять оценку сложности здесь нечего: её в тексте нет, а производительность явно не измеряется.

## RU/EN parity / Согласованность RU/EN

**EN:** The Russian and English sections cover the same concepts, use the same code and examples, give the same predicted outputs and answer, and state the same limits. The wording “the index is outside the allowed range” is equivalent in both. No translation correction is required. Optional addition: state in both languages that this lesson is discussing nonnegative indexes; negative indexing is a valid Python feature counted from the end.

**RU:** Русский и английский разделы охватывают одни и те же понятия, используют одинаковые код и примеры, дают одинаковые ожидаемые результаты и ответ, а также описывают одинаковые ограничения. Формулировка о выходе индекса за допустимый диапазон эквивалентна в обеих версиях. Исправлять перевод не требуется. Необязательное дополнение: на обоих языках уточнить, что здесь рассматриваются неотрицательные индексы; Python также поддерживает отрицательную индексацию от конца.

## Official Python sources / Официальные источники Python

1. Python Tutorial, [Data Structures — More on Lists](https://docs.python.org/3/tutorial/datastructures.html#more-on-lists) — `append()` adds at the end; `pop()` on an empty list raises `IndexError` / `append()` добавляет в конец; `pop()` для пустого списка вызывает `IndexError`.
2. Python Tutorial, [Data Structures — Looping Techniques](https://docs.python.org/3/tutorial/datastructures.html#looping-techniques) — `enumerate()` produces index–value pairs while traversing a sequence / `enumerate()` возвращает пары «индекс — значение» при обходе последовательности.
3. Python Tutorial, [More Control Flow Tools — `for` Statements and `range()`](https://docs.python.org/3/tutorial/controlflow.html#for-statements) and [the `range()` Function](https://docs.python.org/3/tutorial/controlflow.html#the-range-function) — order of iteration, mutation caveat, arithmetic progressions, sequence indexes, and why `enumerate()` is often preferred / порядок обхода, оговорка об изменении коллекции, числовые последовательности, индексы и рекомендация часто выбирать `enumerate()`.
4. Python Standard Library, [Built-in Types — Sequence Types](https://docs.python.org/3/library/stdtypes.html#sequence-types-list-tuple-range) — zero-origin sequence indexing, `len()`, negative-index interpretation, and mutable-sequence iterator behavior / начало индексации с нуля, `len()`, отрицательные индексы и поведение итератора при изменении изменяемой последовательности.
5. Python Standard Library, [Built-in Functions — `enumerate()`](https://docs.python.org/3/library/functions.html#enumerate) — default start value `0`, returned tuples of counter and value / значение начала по умолчанию `0`, пары счётчика и значения.

The explanations above summarize the official documentation; no Python source text was copied into the lesson. / Выше приведены краткие выводы по официальной документации; текст документации Python в урок не копировался.

## Freshness and review boundary / Актуальность и границы проверки

**EN:** The official Python documentation was reviewed as available on 2026-10-12. The lesson front matter still says `source_checked: 2026-10-06`; this audit does not change it. That date should be updated after any lesson edits and their re-review. The source-check date is a record of manual review, not a promise that content refreshes automatically. No tests were run, and no app or trainer runtime behavior was verified.

**RU:** Проверена официальная документация Python, доступная на 2026-10-12. В front matter урока по-прежнему указано `source_checked: 2026-10-06`; этот аудит метаданные не меняет. Обновлять дату следует после правок урока и повторной проверки. Дата проверки источника фиксирует ручной редакторский просмотр, а не обещает автоматическое обновление материала. Тесты не запускались; поведение приложения и работа тренажёра при запуске не проверялись.

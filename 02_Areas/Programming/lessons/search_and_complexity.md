---
subject: programming
lesson_id: programming.search_and_complexity
level: intermediate
languages: ru, en
source_checked: 2026-10-13
source_review_interval_days: 365
---

# Поиск и сложность: считай работу, а не секунды / Search and Complexity: Count Work, Not Seconds

## Русский

### Цель

Сравнить линейный и бинарный поиск по числу сравнений в худшем случае и назвать условие, без которого бинарный поиск неверен.

### Идея и механизм

Сложность описывает, как меняется количество основных операций при росте `n`, а не обещает точное число секунд. В худшем случае линейный поиск может проверить каждый из `n` элементов: его число сравнений растёт примерно пропорционально `n`, или `O(n)`.

Бинарный поиск после каждого сравнения оставляет половину отсортированного диапазона. Для `n` значений ему достаточно не больше `⌈log₂(n + 1)⌉` сравнений на поиск: это `O(log n)`. Например, для 256 элементов верхняя граница здесь равна 9 сравнениям, тогда как линейный поиск может дойти до всех 256.

Обязательное условие — элементы уже отсортированы по тому же правилу сравнения. Если список произвольный, бинарный поиск может дать неверный ответ. Сортировка тоже стоит времени, а вставка в середину списка требует сдвигать элементы: модуль `bisect` из Python быстро ищет позицию, но `insort` в итоге остаётся операцией `O(n)`.

### Выбор структуры данных

Сначала выпиши нужные операции, затем выбирай контейнер:

- `list` — сохраняет последовательность и повторяющиеся элементы, поддерживает позиционный доступ. Подходит, например, для журнала попыток, где важны порядок и каждое повторение.
- `set` — хранит только разные хешируемые значения, не задаёт порядок и не поддерживает индексы. Подходит для множества уже пройденных тем, если нужны устранение дублей и проверка принадлежности.
- `dict` — связывает уникальные хешируемые ключи со значениями; по ключу значение можно получить или заменить. Порядок добавления сохраняется, но это не сортировка по ключу. Подходит, например, для длительности занятия по уникальному `session_id`.

Не обещай себе одинаковую скорость во всех случаях: официальное руководство называет проверку принадлежности во множестве быстрой, но не даёт переносимой гарантии времени для каждой реализации и каждого набора данных. Для списка явный последовательный просмотр может сравнить до `n` элементов. Если важны порядок и дубли, плати за более удобный для них список; если выбираешь множество или словарь ради операций по хешируемым значениям, учитывай дополнительную организацию данных. У множества дубли схлопываются, а словарь хранит ещё и соответствие «ключ → значение».

Чтобы исследовать память на своей версии Python, сравни верхнеуровневые контейнеры:

```python
import sys

topics = ["math", "English", "math", "physics"]
unique_topics = set(topics)
minutes_by_topic = {"math": 25, "English": 20, "physics": 30}

for name, value in (("list", topics), ("set", unique_topics), ("dict", minutes_by_topic)):
    print(name, sys.getsizeof(value))
```

Числа зависят от реализации, версии Python, состава и заполнения контейнера. `sys.getsizeof()` показывает только память, непосредственно занятую объектом-контейнером; он не суммирует строки и другие объекты, на которые контейнер ссылается. Это поверхностный размер контейнера: полезное локальное сравнение, а не полный или универсальный подсчёт памяти.

### Исследуй и потренируйся

Меняй размер отсортированной коллекции от 16 до 1024 элементов. Сравни верхние границы числа сравнений двух методов. Полосы показывают относительное количество сравнений, не время выполнения. Затем ответь: можно ли запустить бинарный поиск по неотсортированному списку? Что ещё надо учесть, если список приходится поддерживать в отсортированном виде после каждой вставки?

### Вопрос

Когда бинарный поиск подходит для коллекции?

### Варианты

- Когда коллекция отсортирована, а правило сравнения согласовано с этим порядком.
- На любом списке: деление пополам само гарантирует, что найден правильный элемент.
- Только когда коллекция содержит ровно 256 элементов.

### Ответ

1

### Разбор

Бинарный поиск отбрасывает половину диапазона лишь потому, что порядок известен. На неотсортированном списке выбранная половина может содержать искомое значение; размер коллекции не исправляет это нарушение.

### Границы модели

Тренажёр сравнивает число сравнений для поиска при заданном `n`; это не benchmark и не измеряет накладные расходы, память, стоимость подготовки данных или аппаратные особенности. `O(n)` и `O(log n)` описывают асимптотический рост в указанной модели. Реальную структуру данных выбирают по требуемым операциям, обновлениям, порядку и ограничениям памяти.

Упражнение по структурам данных проверяет соответствие операций и контейнера; оно не измеряет реальную скорость или объём памяти. Не выводи универсальный `O(1)` из примеров с `set` и `dict`: точные время и память зависят от реализации, данных, операций и распределения нагрузки.

## English

### Goal

Compare worst-case comparison counts for linear and binary search, and state the precondition required for binary search to be correct.

### Idea and mechanism

Complexity describes how the number of basic operations changes as `n` grows; it does not promise an exact number of seconds. In the worst case, linear search may inspect every one of `n` items. Its comparison count grows roughly in proportion to `n`, or `O(n)`.

After each comparison, binary search keeps half of a sorted range. For `n` values, it needs at most `⌈log₂(n + 1)⌉` comparisons for a search: `O(log n)`. For example, this upper bound is 9 comparisons for 256 items, while linear search may inspect all 256.

The required precondition is that the items are already sorted by the same comparison rule. On an arbitrary list, binary search can return the wrong result. Sorting also costs time, and inserting into the middle of a list shifts elements: Python's `bisect` module finds a position quickly, but `insort` remains an `O(n)` operation overall.

### Choosing a data structure

List the required operations first, then choose a container:

- `list` preserves a sequence and duplicate entries and supports positional access. It fits an attempt log when both order and repeated attempts matter.
- `set` stores distinct hashable values, has no defined order, and does not support indexes. It fits a set of completed topics when deduplication and membership checks matter.
- `dict` maps unique hashable keys to values that can be retrieved or replaced by key. It preserves insertion order, but that order is not a key sort. It fits a session-duration lookup by unique `session_id`.

Do not assume identical speed in every case: the official tutorial calls set membership testing fast, but does not promise a portable runtime for every implementation and dataset. An explicit sequential scan of a list may compare up to `n` items. If order and duplicates matter, accept the storage shape of a list; if choosing a set or dictionary for hashable-value operations, account for the extra organization. A set collapses duplicates, while a dictionary also stores key-to-value associations.

To explore memory on your Python build, compare top-level containers:

```python
import sys

topics = ["math", "English", "math", "physics"]
unique_topics = set(topics)
minutes_by_topic = {"math": 25, "English": 20, "physics": 30}

for name, value in (("list", topics), ("set", unique_topics), ("dict", minutes_by_topic)):
    print(name, sys.getsizeof(value))
```

Numbers depend on the implementation, Python version, contents, and container fill. `sys.getsizeof()` reports only the memory directly attributed to the container object; it does not add up strings and other objects referenced by that container. This shallow container size is a useful local comparison, not a complete or universal memory total.

### Explore and practise

Change the size of the sorted collection from 16 to 1024 items. Compare the upper bounds on comparisons for both methods. The bars show relative comparison counts, not runtime. Then answer: can binary search run correctly on an unsorted list? What else matters if the list must stay sorted after every insertion?

### Question

When is binary search suitable for a collection?

### Options

- When the collection is sorted and the comparison rule matches that order.
- On any list: halving alone guarantees the correct item is found.
- Only when the collection contains exactly 256 items.

### Answer

1

### Explanation

Binary search discards half the range only because the ordering is known. In an unsorted list, the discarded half may contain the target; changing the collection size does not fix the missing precondition.

### Limits

The trainer compares comparison counts for search at a chosen `n`; it is not a benchmark and does not measure overhead, memory, data preparation, or hardware effects. `O(n)` and `O(log n)` describe asymptotic growth within the stated model. Choose a real data structure based on the required operations, updates, ordering, and memory constraints.

The data-structure exercise checks whether a container fits the required operations; it does not measure actual runtime or memory. Do not infer a universal `O(1)` guarantee from examples using `set` or `dict`: exact time and memory depend on the implementation, data, operations, and workload.

## Sources

- Python Software Foundation, *Python 3 Library Reference*, “bisect — Array bisection algorithm” (consulted 2026-10-06; documentation version 3.14.8): <https://docs.python.org/3/library/bisect.html>
- The Python documentation explains that `bisect` performs a logarithmic search and that sorted-list insertion through `insort` is `O(n)` overall. Source text is cached only under the Python Software Foundation License Version 2 attribution policy.
- Python Software Foundation, *Python 3 Tutorial*, “Data Structures” (consulted 2026-10-13): lists, sets, dictionaries, membership, uniqueness, and key-value associations: <https://docs.python.org/3/tutorial/datastructures.html>
- Python Software Foundation, *Python 3.14 Library Reference*, “`sys.getsizeof()`” (consulted 2026-10-13): reports the memory directly attributed to an object and does not include referenced objects: <https://docs.python.org/3.14/library/sys.html#sys.getsizeof>
- Source text is cached only under the Python Software Foundation License Version 2 attribution policy.

---
subject: programming
lesson_id: programming.collections_and_loops
level: foundations
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 90
---

# Коллекции и цикл for / Collections and the for Loop

## Русский

### Цель

Объяснять порядок и индексы элементов списка, изменять список добавлением и выбирать между обходом значений и обходом пар «индекс — значение».

### Идея и механизм

Список (`list`) хранит упорядоченную последовательность значений. Позиции считаются с нуля: список из трёх элементов имеет индексы `0`, `1`, `2`, а `len(tasks)` возвращает `3`. `append()` добавляет элемент в конец и меняет исходный список. Цикл `for item in tasks` получает элементы по порядку; `enumerate(tasks)` удобно добавляет к каждому элементу его индекс.

```python
tasks = ["docs", "tests"]
tasks.append("build")

for index, task in enumerate(tasks):
    print(f"{index}: {task}")
```

Результат — `0: docs`, `1: tests`, `2: build`. Для простого обхода только по значениям не нужен `range(len(tasks))`; используй его, когда действительно нужна числовая последовательность. Если во время цикла менять размер той же коллекции, элементы можно пропустить или обработать неожиданно. Для отбора безопаснее собрать новый список.

### Исследуй и потренируйся

В тренажёре добавляй задачи в список и удаляй последнюю. Переключай режим обхода: только значения или пары с индексами. Следи, как операция меняет длину списка и строки результата; после удаления последнего элемента проверь, что пустой список не вызывает обращение по индексу.

Практика: список `steps = ["measure", "calculate"]`; добавь `"check"`, затем предскажи длину и вывод `for index, step in enumerate(steps): print(index, step)`. После этого объясни, почему первый индекс — `0`, а последний — `len(steps) - 1`.

### Вопрос

Что напечатает этот код?

```python
items = ["a", "b"]
items.append("c")
for index, item in enumerate(items):
    print(index, item)
```

### Варианты

- `0 a`, `1 b`, `2 c`
- `1 a`, `2 b`, `3 c`
- `0 c`, `1 b`, `2 a`

### Ответ

1

### Разбор

Первый вариант верен: индексация начинается с нуля, `append()` добавляет `"c"` в конец, а `enumerate()` выдаёт пары индекса и значения в исходном порядке.

### Границы вывода

Тренажёр показывает только ограниченную учебную модель списка и цикла: он не запускает код ученика и не измеряет время выполнения. Индекс — это позиция в конкретной последовательности, а не постоянный идентификатор объекта. Индекс вне допустимого диапазона вызовет `IndexError`; удаление отсутствующего значения и изменение коллекции во время обхода требуют отдельной обработки.

## English

### Goal

Explain list order and indexes, change a list by appending items, and choose between iterating over values and iterating over index–value pairs.

### Idea and mechanism

A list stores an ordered sequence of values. Positions start at zero: a three-item list has indexes `0`, `1`, and `2`, while `len(tasks)` returns `3`. `append()` adds an item to the end and mutates the original list. A `for item in tasks` loop receives values in order; `enumerate(tasks)` conveniently pairs each value with its index.

```python
tasks = ["docs", "tests"]
tasks.append("build")

for index, task in enumerate(tasks):
    print(f"{index}: {task}")
```

The output is `0: docs`, `1: tests`, `2: build`. A simple value-only loop does not need `range(len(tasks))`; use `range` when you actually need a numeric sequence. Changing the size of a collection while iterating over that same collection can skip items or produce surprising behavior. For filtering, building a new list is safer.

### Explore and practise

Add tasks to the trainer's list and remove the last one. Switch between value-only iteration and index–value pairs. Watch how each operation changes the list length and output; after removing the last item, check that an empty list is not indexed.

Practice: start with `steps = ["measure", "calculate"]`, append `"check"`, then predict the length and the output of `for index, step in enumerate(steps): print(index, step)`. Explain why the first index is `0` and the last one is `len(steps) - 1`.

### Question

What does this code print?

```python
items = ["a", "b"]
items.append("c")
for index, item in enumerate(items):
    print(index, item)
```

### Options

- `0 a`, `1 b`, `2 c`
- `1 a`, `2 b`, `3 c`
- `0 c`, `1 b`, `2 a`

### Answer

1

### Explanation

The first option is correct: indexing starts at zero, `append()` adds `"c"` at the end, and `enumerate()` yields index–value pairs in the original order.

### Limits

The trainer shows a small, bounded teaching model of a list and a loop; it does not run learner code or measure execution time. An index is a position in one particular sequence, not a permanent object identifier. An out-of-range index raises `IndexError`; handling missing values and modifying a collection while iterating need separate treatment.

## Sources

- [Python Tutorial: Lists and sequences — Python Software Foundation](https://docs.python.org/3/tutorial/introduction.html)
- [Python Tutorial: for Statements and range — Python Software Foundation](https://docs.python.org/3/tutorial/controlflow.html)

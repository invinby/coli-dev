---
subject: programming
lesson_id: programming.computational_thinking
level: foundations
languages: ru, en
source_checked: 2026-10-16
source_review_interval_days: 90
---

# Алгоритмическое мышление и псевдокод / Computational Thinking and Pseudocode

## Русский

### Цель

Задать контракт задачи, разложить её на однозначные шаги до выбора языка программирования и проверить обычные, граничные и недопустимые входы.

### Идея и механизм

Алгоритм задаёт правила, которые ведут от входных данных к определённому результату. Перед записью кода уточни вход, результат и ограничение задачи. Затем распиши шаги в правильном порядке и проверь каждый переход: условие должно иметь понятный исход, а программа — завершиться.

Псевдокод — это краткое описание логики обычными словами и знакомыми конструкциями вроде «если» и «иначе». У него нет единого синтаксиса: его цель — договориться о поведении до деталей Python, Swift или другого языка.

Пример: найти большее из двух чисел `a` и `b`.

```text
получи a и b
если a больше b:
    выбери a
иначе:
    выбери b
покажи выбранное число
```

Разбивка работает для обычных значений и для границы: если числа равны, ветка «иначе» всё равно возвращает такое же по значению число. Этот пример решает только задачу выбора максимума из двух чисел; следующий раздел обобщает её на непустой список, а ошибки типов и произвольный ввод остаются за пределами контракта.

### Обобщи максимум до списка

Теперь измени контракт: принять непустой список целых чисел и вернуть наибольшее значение. Отрицательные и повторяющиеся числа допустимы, пустой список — нет. Перед чтением первого элемента проверь контракт; пустой список должен приводить к `ValueError`.

```text
проверь, что список не пуст
установи current_maximum = первый элемент списка
для каждого следующего значения:
    если оно больше current_maximum:
        замени current_maximum этим значением
верни current_maximum
```

Начинай с первого элемента, а не с нуля: для `[-8, -2, -5]` правильный максимум равен `-2`, а старт с `0` вернул бы число, которого нет в списке. Трассировка: начальное значение `-8`; `-2` больше и становится максимумом; `-5` меньше и ничего не меняет; результат `-2`.

Спланируй результаты до трассировки и сверь их после неё:

| Назначение теста | Ввод | Ожидаемый результат |
| --- | --- | --- |
| Обычный, максимум в конце | `[2, 4, 9]` | `9` |
| Граница: один допустимый элемент | `[7]` | `7` |
| Все значения отрицательные | `[-8, -2, -5]` | `-2` |
| Максимум повторяется | `[3, 9, 9]` | `9` |
| Недопустимый ввод вне контракта | `[]` | Явная ошибка, например `ValueError` |

Эти примеры проверяют разные ветви и условия цикла, включая ошибочную инициализацию максимума нулём. Они помогают находить дефекты, но не доказывают корректность для всех списков.

### Другой тип задачи: среднее непустого списка

Сначала задай контракт функции: она принимает список целых чисел длиной не меньше одного и возвращает арифметическое среднее. Пустой список этому контракту не соответствует. Разложи вычисление на проверку контракта, накопление суммы, деление на число элементов и возврат результата:

```text
проверь, что список не пуст
установи total = 0
для каждого значения прибавь его к total
раздели total на количество значений
верни среднее
```

Тот же порядок можно выразить на Python:

```python
def mean(values):
    if not values:
        raise ValueError("values must not be empty")
    total = 0
    for value in values:
        total += value
    return total / len(values)
```

Для `[2, 4, 6]` сумма равна `12`, поэтому функция возвращает `4.0`. Для `[7]` результат `7.0`: один элемент проверяет границу допустимой длины. Пустой список вызывает `ValueError`, потому что в этом примере функция заранее обещает работать только с непустым списком.

### Подбери тесты

Тесты должны проверять разные свойства контракта, а не только ещё один обычный пример:

- **Обычный случай:** `[2, 4, 6] → 4.0`; проходит полный цикл и деление на несколько элементов.
- **Граничный случай:** `[7] → 7.0`; подтверждает поведение для одного допустимого значения.
- **Недопустимый случай:** `[] → ValueError`; проверяет отклонение входа за границей контракта.
- **Дополнительный вариант:** `[-2, 2] → 0.0`; это допустимый обычный тест, который отдельно проверяет отрицательные значения и взаимное сокращение.

Каждый тест отвечает на свой вопрос и помогает обнаружить конкретную ошибку; ни три, ни десять примеров не доказывают правильность для всех возможных входов.

### Исследуй и потренируйся

В тренажёре собери алгоритм максимума из двух чисел, затем разложи максимум непустого списка на проверку контракта, начальное значение, обход, обновление и возврат. Проследи список `[-8, -2, -5]`, сверь ожидаемые результаты для пяти тестов, включая один элемент, повтор максимума и пустой ввод. Затем найди контрпример для ошибочной инициализации нулём и исправь алгоритм: для допустимого списка `[-1]` он возвращает `0`, хотя должен вернуть `-1`. После этого разложи вычисление среднего и отнеси четыре набора к обычному, граничному или недопустимому тесту. Случай `[-2, 2]` допустим и отдельно проверяет отрицательные значения и взаимное сокращение. В конце меняй `a` и `b`, включая равные значения, и проследи срабатывающую ветку.

### Вопрос

Почему полезно проверить случай `a = b`, даже если задача звучит как «найти большее число»?

### Варианты

- Чтобы убедиться, что равенство обрабатывается определённой веткой и алгоритм всё равно возвращает допустимый максимум.
- Потому что сравнение `a > b` превращается в истину, когда числа равны.
- Чтобы автоматически проверить любое количество чисел.

### Ответ

1

### Разбор

Первый вариант верен: при равных числах условие `a > b` ложно, срабатывает ветка «иначе» и возвращается `b`, равное `a`. Это проверяет граничное поведение именно этой задачи; такой тест не доказывает корректность для любых других входов.

### Границы вывода

Псевдокод сам по себе не проверяет типы данных, производительность или корректность программной реализации. Алгоритм для двух чисел нельзя без изменений применять к списку; вариант ниже принимает только непустые списки целых чисел и считает пустой список недопустимым. Другие типы и некорректный ввод здесь не рассматриваются. Тщательно выбранные примеры помогают обнаружить дефекты, но не доказывают математическую корректность во всех случаях.

## English

### Goal

Define the task contract, break it into unambiguous steps before choosing a programming language, and check typical, boundary, and invalid inputs.

### Idea and mechanism

An algorithm defines rules that turn input into a specified result. Before writing code, state the input, the required output, and the task's limits. Put the steps in order and check each transition: every condition needs a clear outcome, and the process should finish.

Pseudocode describes logic with concise everyday language and familiar structures such as “if” and “otherwise.” It has no single required syntax; its purpose is to agree on behavior before details of Python, Swift, or another language get in the way.

Example: choose the greater of two numbers, `a` and `b`.

```text
read a and b
if a is greater than b:
    choose a
otherwise:
    choose b
show the chosen number
```

The steps handle ordinary values and the boundary: when the numbers are equal, the “otherwise” branch still returns a number with the correct maximum value. This example only chooses the maximum of two numbers; the next section extends it to a non-empty list, while type errors and arbitrary malformed input remain outside the contract.

### Generalize the maximum to a list

Change the contract: accept a non-empty list of integers and return its greatest value. Negative and repeated values are valid; an empty list is not. Check the contract before reading the first item, and report an empty list with `ValueError`.

```text
check that the list is not empty
set current_maximum = the first item
for each remaining value:
    if it is greater than current_maximum:
        replace current_maximum with it
return current_maximum
```

Start with the first item, not zero. For `[-8, -2, -5]`, the correct maximum is `-2`; starting at `0` would return a value that is not in the list. Trace: start at `-8`; `-2` is greater, so update; `-5` is smaller, so leave the maximum unchanged; return `-2`.

Plan the expected outcomes before tracing, then compare them with the result:

| Test purpose | Input | Expected result |
| --- | --- | --- |
| Typical, maximum at the end | `[2, 4, 9]` | `9` |
| Boundary: one valid item | `[7]` | `7` |
| All values are negative | `[-8, -2, -5]` | `-2` |
| The maximum is repeated | `[3, 9, 9]` | `9` |
| Invalid input outside the contract | `[]` | Explicit error, such as `ValueError` |

These cases exercise different parts of the contract and loop. They can expose defects such as initializing the maximum to zero, but they do not prove correctness for every possible list.

### A different task: the mean of a non-empty list

Start with a function contract: it accepts a list of integers containing at least one item and returns their arithmetic mean. An empty list does not satisfy that contract. Break the calculation into a contract check, sum accumulation, division by the item count, and returning the result:

```text
check that the list is not empty
set total = 0
add each value to total
divide total by the number of values
return the mean
```

The same order can be expressed in Python:

```python
def mean(values):
    if not values:
        raise ValueError("values must not be empty")
    total = 0
    for value in values:
        total += value
    return total / len(values)
```

For `[2, 4, 6]`, the sum is `12`, so the function returns `4.0`. For `[7]`, the result is `7.0`: one item checks the smallest valid list length. An empty list raises `ValueError` because this example's contract explicitly requires a non-empty list.

### Choose test cases

Tests should check different parts of the contract, not just another ordinary example:

- **Typical case:** `[2, 4, 6] → 4.0`; exercises the full loop and division over several items.
- **Boundary case:** `[7] → 7.0`; checks behavior at the smallest valid input length.
- **Invalid case:** `[] → ValueError`; checks rejection of input outside the contract.
- **Additional variation:** `[-2, 2] → 0.0`; this is a valid typical test that separately checks negative values and cancellation.

Each test answers a different question and can expose a specific defect; three or ten examples still do not prove correctness for every possible input.

### Explore and practise

In the trainer, assemble the two-number maximum, then decompose the non-empty-list maximum into its contract check, starting value, scan, update, and return. Trace `[-8, -2, -5]` and check the expected outcomes for five tests, including a single item, a repeated maximum, and empty input. Then find a counterexample for the faulty zero initialization and repair the algorithm: for the valid list `[-1]`, it returns `0` although it must return `-1`. Next, decompose the mean calculation and classify four cases as typical, boundary, or invalid. `[-2, 2]` is valid and separately checks negative values and cancellation. Finally, change `a` and `b`, including equal values, and follow the branch that runs.

### Question

Why is it useful to check the case `a = b` when the task asks you to find the greater number?

### Options

- To make sure equality follows a defined branch and the algorithm still returns a valid maximum.
- Because the comparison `a > b` becomes true when the numbers are equal.
- To automatically handle any number of inputs.

### Answer

1

### Explanation

The first option is correct: when the numbers are equal, `a > b` is false, so the “otherwise” branch returns `b`, which equals `a`. This checks a boundary for this particular task; it does not prove correctness for every possible input.

### Limits

Pseudocode alone does not validate data types, performance, or a program implementation. The two-number algorithm cannot be applied unchanged to a list; the list version in this lesson accepts only non-empty integer lists and reports an empty list as invalid. Other types and malformed input are not covered. Carefully chosen examples can expose defects, but they do not constitute a mathematical proof for every case.

## Sources

- NIST CSRC Glossary, “Algorithm” (official definition; consulted 2026-10-06) / Глоссарий NIST CSRC, “Algorithm” (официальное определение; проверен 2026-10-06): <https://csrc.nist.gov/glossary/term/algorithm>
- CSTA, 2026 PK–12 Computer Science Standards, algorithmic problem-solving practices (official standards; consulted 2026-10-16) / CSTA, стандарты информатики для школ 2026 года, практики алгоритмического решения задач (официальный стандарт; проверен 2026-10-16): <https://csteachers.org/pk12standards/view/>
- College Board, AP Computer Science Principles Course and Exam Description, CRD-2.J (expected outputs or behaviors for checking correctness; consulted 2026-10-16) / College Board, описание курса и экзамена AP Computer Science Principles, CRD-2.J (ожидаемые результаты или поведение для проверки корректности; проверено 2026-10-16): <https://apcentral.collegeboard.org/media/pdf/ap-computer-science-principles-course-and-exam-description.pdf>
- Python 3 Tutorial, “More Control Flow Tools” (official Python documentation; consulted 2026-10-16) / Руководство Python 3, «Дополнительные средства управления потоком выполнения» (официальная документация Python; проверена 2026-10-16): <https://docs.python.org/3/tutorial/controlflow.html>
- Python 3 built-in exceptions, “ValueError” (official Python documentation; consulted 2026-10-16) / Встроенные исключения Python 3, “ValueError” (официальная документация Python; проверена 2026-10-16): <https://docs.python.org/3/library/exceptions.html#ValueError>
- Python 3 `unittest` documentation (unit-test cases and expected results; consulted 2026-10-16) / Документация Python 3 `unittest` (тест-кейсы и ожидаемые результаты; проверена 2026-10-16): <https://docs.python.org/3/library/unittest.html>

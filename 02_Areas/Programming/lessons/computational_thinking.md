---
subject: programming
lesson_id: programming.computational_thinking
level: foundations
languages: ru, en
source_checked: 2026-10-15
source_review_interval_days: 90
---

# Алгоритмическое мышление и псевдокод / Computational Thinking and Pseudocode

## Русский

### Цель

Разложить задачу на однозначные шаги, записать их до выбора языка программирования и проверить поведение на обычном и граничном примере.

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

Разбивка работает для обычных значений и для границы: если числа равны, ветка «иначе» всё равно возвращает такое же по значению число. Этот пример решает только задачу выбора максимума из двух чисел; он не описывает ошибки ввода, список произвольной длины или обработку нечисловых значений.

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
- **Дополнительный вариант:** `[-2, 2] → 0.0`; проверяет отрицательные значения и взаимное сокращение.

Каждый тест отвечает на свой вопрос и помогает обнаружить конкретную ошибку; ни три, ни десять примеров не доказывают правильность для всех возможных входов.

### Исследуй и потренируйся

В тренажёре последовательно собери алгоритм максимума, разложи вычисление среднего, затем отнеси три набора к обычному, граничному или недопустимому тесту. Сверь каждый с контрактом; после этого меняй `a` и `b`, включая равные значения, и проследи срабатывающую ветку. Перед проверкой алгоритма заранее выбери тесты для разных условий и границ, а не только примеры, где всё «обычно работает».

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

Псевдокод сам по себе не проверяет типы данных, ошибки ввода, производительность или корректность реализации. Алгоритм для двух чисел нельзя без изменений применять к пустому списку или произвольному числу значений. Проверки нескольких тщательно выбранных примеров помогают обнаружить дефекты, но не являются математическим доказательством во всех случаях.

## English

### Goal

Break a task into unambiguous steps, describe them before choosing a programming language, and check both a typical input and a boundary case.

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

The steps handle ordinary values and the boundary: when the numbers are equal, the “otherwise” branch still returns a number with the correct maximum value. This example only chooses the maximum of two numbers; it does not define invalid-input behavior, a list of arbitrary length, or non-numeric values.

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
- **Additional variation:** `[-2, 2] → 0.0`; checks negative values and cancellation.

Each test answers a different question and can expose a specific defect; three or ten examples still do not prove correctness for every possible input.

### Explore and practise

In the trainer, assemble the maximum algorithm, decompose the mean calculation, then classify three inputs as a typical, boundary, or invalid test. Check each against the contract; afterward, change `a` and `b`, including equal values, and follow the branch that runs. Choose tests for different conditions and boundaries before trusting an algorithm, not only cases where it “usually works.”

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

Pseudocode does not validate data types, invalid input, performance, or an implementation. An algorithm for two numbers cannot be applied unchanged to an empty list or an arbitrary number of values. Carefully chosen examples can expose defects, but they do not constitute a mathematical proof for every case.

## Sources

- NIST CSRC Glossary, “Algorithm” (official definition; consulted 2026-10-06): <https://csrc.nist.gov/glossary/term/algorithm>
- Python 3 Tutorial, “More Control Flow Tools” (official Python documentation; consulted 2026-10-15): <https://docs.python.org/3/tutorial/controlflow.html>
- Python 3 built-in exceptions, “ValueError” (official Python documentation; consulted 2026-10-15): <https://docs.python.org/3/builtins/exceptions.html#ValueError>

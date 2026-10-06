---
subject: programming
lesson_id: programming.computational_thinking
level: foundations
languages: ru, en
source_checked: 2026-10-06
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

### Исследуй и потренируйся

В тренажёре собери шаги в правильном порядке. Затем меняй `a` и `b`, включая равные значения, и проследи: какая ветка срабатывает и почему результат остаётся корректным? Для проверки алгоритма заранее выбери примеры, которые проверяют разные ветки и границу `a = b`.

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

### Explore and practise

Build the steps in the correct order in the trainer. Then change `a` and `b`, including equal values, and follow which branch runs and why the result remains valid. Choose examples that exercise both branches and the boundary `a = b` before trusting the algorithm.

### Question

Why is it useful to check the case `a = b`, even when the task says “find the greater number”?

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
- Python 3.14 Tutorial, “More Control Flow Tools” (official Python documentation; consulted 2026-10-06): <https://docs.python.org/3/tutorial/controlflow.html>

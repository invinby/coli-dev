---
subject: programming
lesson_id: programming.conditions_loops_functions
level: foundations
languages: ru, en
source_checked: 2026-10-05
source_review_interval_days: 90
---

# Условия, циклы и функции / Conditions, Loops, and Functions

## Русский

### Цель

Превратить задачу из нескольких повторяющихся шагов в функцию, которая принимает данные, выбирает ветку и возвращает проверяемый результат.

### Идея и механизм

Условие `if` выбирает ветвь по истинности выражения. Цикл `for` последовательно получает элементы последовательности; его переменная на каждом шаге указывает на текущий элемент. Функция объединяет шаги под именем: параметры — её входы, `return` — результат для вызывающего кода.

```python
def count_even(numbers):
    count = 0
    for number in numbers:
        if number % 2 == 0:
            count += 1
    return count
```

Для `[2, 5, 8]` функция возвращает `2`: цикл проверяет каждое число, остаток `number % 2` равен нулю у чётных, а `count` увеличивается только в этой ветви. `return` завершает функцию и отдаёт значение; `print` лишь показывает текст и сам по себе не заменяет возвращаемый результат.

### Исследуй и потренируйся

Перед запуском предскажи значение `number` и `count` после каждого шага. Затем поменяй список, включая пустой список и числа `0`, `-2`, `3`. Проверь, что результат равен числу элементов, которые прошли условие.

Задача: измени функцию так, чтобы она считала числа больше 10. Ответ: условие цикла можно заменить на `if number > 10:`; логика накопления остаётся такой же.

### Вопрос

Функция считает чётные числа в `[2, 5, 8]`. Что она должна вернуть?

### Варианты

- `1`
- `2`
- `None`

### Ответ

2

### Разбор

Чётные числа — `2` и `8`, поэтому функция возвращает `2`. Если она только печатает результат, вызывающая программа получит `None`, а не значение для дальнейшего использования.

### Границы и безопасный запуск

Этот пример проходит список один раз, поэтому число проверок растёт вместе с длиной списка (`O(n)`). Он не проверяет, что каждый элемент — целое число; реальные функции должны либо документировать ожидаемый тип, либо валидировать вход. Код урока анализируй или запускай только в изолированной среде: произвольный код из чата нельзя исполнять без ограничений.

## English

### Goal

Turn repeated steps into a function that accepts data, selects a branch, and returns a result that can be checked.

### Idea and mechanism

An `if` statement selects a branch based on a condition. A `for` loop visits the items of a sequence in order; its loop variable refers to the current item. A function groups steps under a name: parameters are inputs, and `return` sends a result back to the caller.

```python
def count_even(numbers):
    count = 0
    for number in numbers:
        if number % 2 == 0:
            count += 1
    return count
```

For `[2, 5, 8]`, the function returns `2`: the loop checks each number, `number % 2` is zero for even values, and `count` increases only in that branch. `return` ends the function and gives a value to the caller; `print` displays text and does not replace a returned result.

### Explore and practise

Before running the code, predict `number` and `count` after each step. Then change the list, including an empty list and the values `0`, `-2`, and `3`. Check that the result equals the number of items that pass the condition.

Try changing the function to count values greater than 10. Use `if number > 10:`; the accumulation logic stays the same.

### Question

What should a function return when it counts the even numbers in `[2, 5, 8]`?

### Options

- `1`
- `2`
- `None`

### Answer

2

### Explanation

The even numbers are `2` and `8`, so the function returns `2`. If it only prints the result, the caller gets `None` rather than a value it can use.

### Limits and safe execution

This example makes one pass through the list, so the number of checks grows with list length (`O(n)`). It does not check that every item is an integer; real functions should document or validate expected input. Analyse or run lesson code only in an isolated environment; never execute arbitrary chat code without restrictions.

## Sources

- Python 3 Tutorial, “More Control Flow Tools”: <https://docs.python.org/3/tutorial/controlflow.html>
- Python 3 Tutorial, “Defining Functions”: <https://docs.python.org/3/tutorial/controlflow.html#defining-functions>

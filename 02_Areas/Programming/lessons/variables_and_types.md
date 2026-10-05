---
subject: programming
lesson_id: programming.variables_and_types
level: foundations
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 90
---

# Переменные и типы данных / Variables and Data Types

## Русский

### Цель

Объяснять, какое значение связано с именем, отличать основные типы данных и предсказывать результат повторного присваивания.

### Идея и механизм

В Python имя — это метка, через которую программа обращается к значению. Присваивание `score = 12` связывает имя `score` с целым числом. В выражении `score = score + 1` сначала вычисляется правая часть, затем то же имя связывается с новым результатом — `13`.

```python
score = 12          # int: целое число
ratio = 0.75        # float: число с плавающей точкой
label = "уровень"   # str: текст
is_ready = True     # bool: логическое значение

score = score + 1
print(score)        # 13
print(type(label).__name__)  # str
```

Имя не «содержит коробку», в которую навсегда положен один вид данных. Во время выполнения ему можно присвоить значение другого типа; в примере `score = "готово"` имя после этой строки связано с текстом. Python динамически определяет тип значения, но это не означает, что разные типы всегда можно смешивать: например, сложение числа и строки без явного преобразования вызывает `TypeError`.

### Исследуй и потренируйся

Сначала предскажи результат для `score = 12`, затем `score = "12"`. В тренажёре переключай переприсваивание и смотри, как меняются значение и тип. Обрати внимание: текст `"12"` выглядит как число, но остаётся строкой; Python не преобразовал его автоматически.

Задание: измени начальное число на `-3` и ещё раз прибавь `1`. Какое значение будет у имени после вычисления? Затем объясни, почему `"12" + 1` не равнозначно `12 + 1`.

### Вопрос

Какой результат и тип у `amount` после выполнения `amount = 8 / 5`?

### Варианты

- `1.6`, тип `float`
- `1.6`, тип `str`
- `1`, тип `int`

### Ответ

1

### Разбор

Первый вариант верен: оператор `/` в Python выполняет обычное деление и возвращает значение типа `float`, даже если результат деления целый. Кавычки превратили бы запись в текст, но здесь их нет.

### Границы вывода

Имена в Python чувствительны к регистру: `score` и `Score` — разные имена. Присваивание имени не проверяет смысл значения и не гарантирует, что последующие операции подходят его типу. Функция `type()` полезна для обучения и диагностики, но в прикладном коде часто важнее проверять требуемое поведение или явно преобразовывать и проверять ввод. Тренажёр показывает модель двух присваиваний и не исполняет введённый учеником код.

## English

### Goal

Explain which value a name refers to, distinguish common data types, and predict the result of assigning a new value to a name.

### Idea and mechanism

In Python, a name is a label the program uses to refer to a value. The assignment `score = 12` binds the name `score` to an integer. In `score = score + 1`, Python first evaluates the right-hand expression and then binds the same name to the new result, `13`.

```python
score = 12          # int: an integer
ratio = 0.75        # float: a floating-point number
label = "level"     # str: text
is_ready = True     # bool: a Boolean value

score = score + 1
print(score)        # 13
print(type(label).__name__)  # str
```

A name is not a box permanently restricted to one kind of data. At runtime it can be assigned a value of another type; after `score = "ready"`, for example, the name refers to text. Python determines the type of a value at runtime, but that does not mean different types can always be mixed: adding a number and a string without an explicit conversion raises `TypeError`.

### Explore and practise

Predict the result first for `score = 12`, then for `score = "12"`. Toggle reassignment in the trainer and observe how the value and type change. The text `"12"` looks like a number, but it is still a string; Python has not converted it automatically.

Try changing the initial number to `-3` and adding `1` again. What value is associated with the name afterwards? Then explain why `"12" + 1` is not the same operation as `12 + 1`.

### Question

What are the result and type of `amount` after `amount = 8 / 5`?

### Options

- `1.6`, type `float`
- `1.6`, type `str`
- `1`, type `int`

### Answer

1

### Explanation

The first option is correct: Python's `/` operator performs ordinary division and returns a `float`, even when the quotient is a whole number. Quotes would make the value text, but there are no quotes here.

### Limits of the inference

Python names are case-sensitive: `score` and `Score` are different names. Assignment does not check whether a value makes sense or whether later operations support its type. `type()` is useful for learning and diagnostics, while application code often needs to validate expected behavior or explicitly convert and validate input. The trainer models two assignments and does not execute learner-entered code.

## Sources

- Python 3.14 Tutorial, “An Informal Introduction to Python” (official Python documentation; consulted 2026-10-06): <https://docs.python.org/3/tutorial/introduction.html>

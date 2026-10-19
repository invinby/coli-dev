---
subject: programming
lesson_id: programming.variables_and_types
level: foundations
languages: ru, en
source_checked: 2026-10-15
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

### Ввод пользователя — это текст

`input()` читает строку и возвращает `str`, даже если пользователь ввёл цифры. Если дальше программе нужно целое число, преобразуй строку через `int()`:

```python
raw_text = input("Сколько задач ты решил? ")
count = int(raw_text)
print(count + 1)
```

Введи `12`: `raw_text` сначала будет строкой `"12"`, затем `count` станет целым числом `12`. Ввод `twelve` или `3.5` нельзя преобразовать через `int()` как строку целого числа, поэтому возникнет `ValueError`. Чтобы программа не завершалась без объяснения, обработай неверный ввод:

```python
raw_text = input("Сколько задач ты решил? ")
try:
    count = int(raw_text)
except ValueError:
    print("Введи целое число")
else:
    print(count + 1)
```

В тренажёре сначала попробуй `12`, затем при желании `-12`, `twelve`, `3.5` и пустой ввод. Результаты попыток преобразования сохраняются для этого урока без отправки введённой строки. Тренажёр проверяет только простое текстовое преобразование и не запускает введённый код.

### Мини-проект: учёт минут практики

Собери отчёт о занятии: передай функции минуты двух занятий, сложи их и верни итог. В уроке ColiDev есть редактор этого проекта: поля принимают два неотрицательных целых числа, а кнопка запускает `solve(values)` в ограниченном учебном интерпретаторе во встроенном локальном сервисе.

```python
def solve(values):
    earlier_minutes = values[0]
    today_minutes = values[1]
    total_minutes = earlier_minutes + today_minutes
    return total_minutes
```

Оставь значения `12` и `8`: результат должен быть `20`. Затем измени функцию, запусти её ещё раз и сравни результат с суммой. Успешная проверка записывается в прогресс обучения; код и поля сохраняются локально на этом Mac.

Ограничение важно: редактор выполняет только небольшой безопасный поднабор Python через AST-интерпретатор. Он не запускает произвольные скрипты, `input()`, `print()`, `try/except`, импорты, доступ к файлам или сети; запрос не отправляется модели ИИ. Полную консольную версию можно написать отдельно в обычном Python после установки Python. В приложении ввод проверяет интерфейс: только неотрицательные целые числа, сумма которых помещается в обычное целое число.

Следующий шаг после условий и файлов — расширить отчёт третьим параметром, например минутами чтения. Отдельно спроектируй проверку неверного текста и отрицательных значений; текущая функция получает уже проверенные числа и сама такую проверку не выполняет.

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

Имена в Python чувствительны к регистру: `score` и `Score` — разные имена. Присваивание имени не проверяет смысл значения и не гарантирует, что последующие операции подходят его типу. Функция `type()` полезна для обучения и диагностики, но в прикладном коде часто важнее проверять требуемое поведение или явно преобразовывать и проверять ввод. Тренажёр симулирует только простые целые числа ASCII в диапазоне `Swift Int`; он не выполняет код, не покрывает весь синтаксис Python `int()` и не ограничивает диапазон настоящих целых чисел Python.

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

### User input is text

`input()` reads a line and returns it as `str`, even when the user types digits. If the program needs an integer, convert that string with `int()`:

```python
raw_text = input("How many tasks did you finish? ")
count = int(raw_text)
print(count + 1)
```

Enter `12`: `raw_text` is first the string `"12"`, and then `count` becomes the integer `12`. Text such as `twelve` or `3.5` cannot be converted to an integer string by `int()`, so Python raises `ValueError`. Handle invalid input to give the user a useful message:

```python
raw_text = input("How many tasks did you finish? ")
try:
    count = int(raw_text)
except ValueError:
    print("Enter a whole number")
else:
    print(count + 1)
```

Try `12` first, then optionally `-12`, `twelve`, `3.5`, and empty input. Conversion attempts are saved for this lesson without sending the entered text. The trainer checks only simple text conversion and does not run learner-entered code.

### Mini-project: practice minute total

Build a session report: pass the minutes from two study sessions to a function, add them, and return the total. ColiDev’s lesson includes an editor for this project: enter two non-negative whole numbers in the fields, then run `solve(values)` in the app’s bounded teaching interpreter on its bundled local service.

```python
def solve(values):
    earlier_minutes = values[0]
    today_minutes = values[1]
    total_minutes = earlier_minutes + today_minutes
    return total_minutes
```

Keep the inputs `12` and `8`: the result should be `20`. Then edit the function, run it again, and compare its result with the sum. A successful check is recorded in learning progress; the code and inputs are saved locally on this Mac.

The limit matters: the editor executes only a small safe subset of Python through an AST interpreter. It does not run arbitrary scripts, `input()`, `print()`, `try/except`, imports, file or network access; no request is sent to an AI model. You can write a full console version separately in regular Python after installing Python. In the app, the interface validates input: only non-negative whole numbers whose sum fits a standard integer.

After learning conditionals and files, extend the report with a third parameter, such as reading time. Separately design validation for non-numeric text and negative values; the current function receives validated numbers and does not perform that validation itself.

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

Python names are case-sensitive: `score` and `Score` are different names. Assignment does not check whether a value makes sense or whether later operations support its type. `type()` is useful for learning and diagnostics, while application code often needs to validate expected behavior or explicitly convert and validate input. The trainer simulates only simple ASCII whole numbers within the `Swift Int` range; it does not execute code, cover all Python `int()` syntax, or limit the range of real Python integers.

## Sources

- Python 3 built-in functions, `input()` and `int()` (official Python documentation; consulted 2026-10-15): <https://docs.python.org/3/builtins/functions.html#input>, <https://docs.python.org/3/builtins/functions.html#int>
- Python 3 built-in exceptions, `ValueError` (official Python documentation; consulted 2026-10-15): <https://docs.python.org/3/builtins/exceptions.html#ValueError>

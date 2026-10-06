---
subject: programming
lesson_id: programming.debugging_tests_and_git
level: foundations
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 90
---

# Отладка, тесты и Git / Debugging, Tests, and Git

## Русский

### Цель

Научиться сужать место дефекта по сообщению об ошибке, проверять причину маленьким примером и убеждаться тестом, что исправление работает.

### Идея и механизм

Сначала воспроизведи проблему теми же входными данными. В traceback найди тип и текст исключения внизу, затем строку и вызванные функции выше. Это подсказки, а не готовая правка: отмеченная строка может лишь обнаружить ошибку, созданную раньше. Ошибки синтаксиса и исключения времени выполнения показываются по-разному.

```python
def double(n):
    return n * 2

assert double(3) == 6
```

У проверки есть конкретное ожидание. Сравни ожидаемое с фактическим, проверь само требование и добавь граничный случай (например, ноль или пустой список), когда он важен. Если тест упал, не удаляй его и не меняй ожидаемое на фактическое, пока не выяснил, какая сторона противоречит требованиям.

`assert` в этом примере — короткая проверка для изучения поведения. В Python оптимизированный запуск может убрать `assert`, поэтому для постоянного набора тестов используй тестовый фреймворк, а не полагайся только на эти выражения.

### Рабочий цикл

1. Повтори ошибку и сохрани точный вход.
2. Прочитай тип исключения, сообщение и соответствующую строку traceback.
3. Сформулируй проверяемую гипотезу; меняй за раз только одну причину.
4. Запусти узкий тест и связанные проверки.
5. Посмотри diff и зафиксируй понятное изменение в Git.

### Исследуй и потренируйся

В тренажёре выбери диагностический шаг для `NameError`, `IndexError` или упавшего `assert`. Сначала определи симптом и границу, затем сверь объяснение. Это заранее заданные фрагменты; приложение не запускает произвольный код.

На бумаге добавь к функции `double` тест для `double(0)` и поясни ожидаемое значение. Затем представь, что тест не проходит: перечисли, какие вход, строку и требование проверишь до правки.

### Вопрос

Последняя строка traceback говорит `NameError: name 'totel' is not defined`; выше есть `total = 12` и `print(totel)`. Какой первый полезный шаг?

### Варианты

- Сверить имя в месте использования с объявленным именем и проверить гипотезу исправлением опечатки.
- Обернуть `print` в `try/except Exception`.
- Удалить строку печати, чтобы ошибка исчезла.

### Ответ

1

### Разбор

В коде объявлено `total`, а читается `totel`. `NameError` указывает на имя, которого нет в текущей области видимости. Исправление нужно проверить повторным запуском воспроизводимого случая.

### Границы и безопасный запуск

Одна ошибка иногда маскирует следующую. Исправление одного случая не доказывает корректность всей программы; нужны тесты по требованию, граничным случаям и регрессии. Текст исключения и строка traceback могут указывать место проявления, а не исходную причину. Git сохраняет историю изменений, но сам по себе не доказывает правильность кода.

## English

### Goal

Use an error message to narrow down a defect, check its cause with a small example, and verify a fix with a test.

### Idea and mechanism

First reproduce the problem with the same input. In a traceback, inspect the exception type and message at the bottom, then the relevant source line and callers above it. These are clues, not an automatic fix: the highlighted line may only reveal an earlier mistake. Syntax errors and runtime exceptions are reported differently.

```python
def double(n):
    return n * 2

assert double(3) == 6
```

A test has a concrete expectation. Compare expected and actual values, check the requirement itself, and add a boundary case such as zero or an empty list when relevant. If a test fails, do not delete it or change its expected value to match the result until you know which side conflicts with the requirement.

The `assert` here is a short check for learning. Python's optimized mode can remove `assert` statements, so use a test framework for a durable test suite instead of relying on these expressions alone.

### A practical loop

1. Reproduce the failure and keep the exact input.
2. Read the exception type, message, and relevant traceback line.
3. Form a testable hypothesis; change one cause at a time.
4. Run the focused test and related checks.
5. Review the diff and record a clear change in Git.

### Explore and practise

Choose a diagnostic step for a `NameError`, `IndexError`, or failed `assert` in the trainer. Identify the symptom and boundary before checking the explanation. The examples are fixed; the app does not run arbitrary code.

Add a test for `double(0)` on paper and state the expected result. Then imagine that it fails: list the input, line, and requirement you would inspect before editing the code.

### Question

The last traceback line says `NameError: name 'totel' is not defined`; above it are `total = 12` and `print(totel)`. What is a useful first step?

### Options

- Compare the used name with the declared name and test the misspelling hypothesis.
- Wrap `print` in `try/except Exception`.
- Delete the print line to make the error disappear.

### Answer

1

### Explanation

The code defines `total` but reads `totel`. `NameError` means the name is not defined in the current scope. Re-run the reproducible case to verify the correction.

### Limits and safe execution

One error can hide another. Fixing one case does not prove the entire program correct; test the requirement, boundaries, and regressions. The exception text and traceback line may show where a problem surfaced rather than its original cause. Git records change history but does not prove that code is correct.

## Sources

- Python Tutorial, “Errors and Exceptions”: <https://docs.python.org/3/tutorial/errors.html>
- Python Language Reference, “The `assert` statement”: <https://docs.python.org/3/reference/simple_stmts.html#the-assert-statement>

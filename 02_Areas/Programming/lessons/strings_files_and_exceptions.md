---
subject: programming
lesson_id: programming.strings_files_and_exceptions
level: foundations
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 90
---

# Строки, файлы и исключения / Strings, Files, and Exceptions

## Русский

### Цель

Преобразовать строковые данные в значения, безопасно прочитать текстовый файл и отличить ожидаемую ошибку данных от ошибки доступа к файлу.

### Идея и механизм

Текст читается как строка; если из него нужно получить число, преобразование `int(text)` может завершиться `ValueError`. При открытии файла может возникнуть `OSError`, например `FileNotFoundError`, если файла нет. `with` закрывает файл при обычном завершении блока и при исключении.

```python
from pathlib import Path

def sum_numbers(path: Path) -> int:
    with path.open("r", encoding="utf-8") as file:
        return sum(int(line.strip()) for line in file if line.strip())

try:
    total = sum_numbers(Path("scores.txt"))
except FileNotFoundError:
    print("Файл не найден")
except ValueError:
    print("В файле есть строка, которая не является целым числом")
except OSError:
    print("Не удалось прочитать файл")
```

`strip()` убирает пробельные символы по краям строки. Пустые строки пропускаются, но строка вроде `"12 points"` не является целым числом и вызовет `ValueError`. Более конкретный `FileNotFoundError` обработан отдельно; остальные ошибки ввода/вывода остаются на более общем `OSError`.

### Исследуй и потренируйся

В тренажёре выбери ситуацию и подбери объяснение: файл отсутствует, файл содержит неверное число или все строки можно преобразовать. Затем проследи, какая часть `try` выполняется и какой именно обработчик подходит. Это фиксированные примеры, файловая система и пользовательский код не запускаются.

На бумаге проверь строки `" 7 "`, `""`, `"-3"` и `"4.5"`. Для каждой укажи результат `strip()`, будет ли строка пропущена и сработает ли `int()`.

### Вопрос

Файл существует, но одна непустая строка равна `"twelve"`. Какое исключение возникает при `int(line.strip())`?

### Варианты

- `FileNotFoundError`
- `ValueError`
- Ошибки не будет: строка станет нулём

### Ответ

2

### Разбор

`int()` не может разобрать слово `"twelve"` как целое число, поэтому возникает `ValueError`. Файл при этом открылся успешно; это ошибка содержимого, а не отсутствия файла.

### Границы и безопасный запуск

Не открывай произвольный путь из недоверенного ввода: ограничивай допустимую папку и не считай имя файла безопасным только потому, что оно выглядит обычным. Режим `"w"` обнуляет существующий файл, поэтому для учебного чтения здесь указан только `"r"`. `except Exception` без необходимости может скрыть дефекты программы; обрабатывай ожидаемые ошибки конкретно, а неожиданные передавай выше. Для больших файлов построчное чтение не требует загружать весь файл сразу, но `sum()` всё равно хранит текущую сумму и проходит данные целиком.

## English

### Goal

Convert text into values, read a text file safely, and distinguish invalid data from a file-access problem.

### Idea and mechanism

Text is read as strings. If a number is needed, converting with `int(text)` can raise `ValueError`. Opening a file can raise `OSError`; for example, a missing path raises `FileNotFoundError`. A `with` statement closes the file when its block finishes, including when an exception interrupts the block.

```python
from pathlib import Path

def sum_numbers(path: Path) -> int:
    with path.open("r", encoding="utf-8") as file:
        return sum(int(line.strip()) for line in file if line.strip())

try:
    total = sum_numbers(Path("scores.txt"))
except FileNotFoundError:
    print("File not found")
except ValueError:
    print("A line in the file is not an integer")
except OSError:
    print("Could not read the file")
```

`strip()` removes surrounding whitespace. Blank lines are skipped, but a line such as `"12 points"` is not an integer and raises `ValueError`. The more specific `FileNotFoundError` is handled separately; other I/O failures can reach the broader `OSError` handler.

### Explore and practise

Choose a fixed situation in the trainer and identify what happened: the file is missing, it contains invalid numeric text, or all non-empty lines can be converted. Then trace which part of `try` runs and which handler matches. These are bounded examples; the trainer does not access the file system or execute learner code.

On paper, inspect `" 7 "`, `""`, `"-3"`, and `"4.5"`. For each value, state the result of `strip()`, whether the line is skipped, and whether `int()` succeeds.

### Question

The file exists, but one non-empty line is `"twelve"`. Which exception is raised by `int(line.strip())`?

### Options

- `FileNotFoundError`
- `ValueError`
- No error: the string becomes zero

### Answer

2

### Explanation

`int()` cannot parse the word `"twelve"` as an integer, so it raises `ValueError`. The file opened successfully; this is invalid content, not a missing-file error.

### Limits and safe execution

Do not open an arbitrary path from untrusted input: restrict allowed directories and do not assume a filename is safe because it looks ordinary. Mode `"w"` truncates an existing file, so this lesson uses only read mode `"r"`. A broad `except Exception` can hide programming defects; handle expected failures specifically and let unexpected ones propagate. Iterating over a large file avoids loading all its text at once, while `sum()` still reads the complete input and keeps a running total.

## Sources

- Python 3 Tutorial, “Input and Output”: <https://docs.python.org/3/tutorial/inputoutput.html>
- Python 3 Tutorial, “Errors and Exceptions”: <https://docs.python.org/3/tutorial/errors.html>

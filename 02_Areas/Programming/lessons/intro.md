---
subject: programming
lesson_id: intro.programming
level: foundations
languages: ru, en
source_checked: 2026-10-12
source_review_interval_days: 365
---

# Условия и ветвление / Conditions and Branching

## Русский

Это короткий ознакомительный пример о ветвлении, а не отдельная полная глава. Дальше в курсе тема условий продолжается вместе с циклами и функциями.

### Цель

Прослеживать, как программа проверяет условие и выбирает ветку выполнения.

### Идея и механизм

Условный оператор if вычисляет условие, которое даёт истину или ложь. Если оно истинно, выполняется соответствующий блок; elif проверяет следующую альтернативу, когда предыдущие условия не подошли; необязательный else задаёт запасной путь. В Python границы блоков задаются отступами.

```python
temperature = -2
if temperature < 0:
    state = "ice"
elif temperature < 20:
    state = "cool"
else:
    state = "warm"
print(state)
```

При `temperature = -2` первая проверка истинна, поэтому программа печатает `ice`. Остальные ветки этой цепочки пропускаются.

### Исследуй и потренируйся

По очереди подставь вместо `-2` значения `8` и `25`. Проследи, какое первое условие сработает, и предскажи вывод. Ожидаемые результаты: `-2 → "ice"` («лёд»), `8 → "cool"` («прохладно»), `25 → "warm"` («тепло»). Затем поставь проверку `temperature < 20` перед `temperature < 0`: значение `-2` попадёт в первую ветку и даст `"cool"`. Объясни, почему порядок условий изменил результат.

### Вопрос

Какое значение устанавливает первая ветка, если temperature = -2?

### Варианты

- «ice»
- «cool»
- «warm»

### Ответ

1

### Разбор

Условие temperature < 0 истинно для -2, поэтому выполняется первая ветка и выбирается «ice»; последующие условия уже не проверяются.

### Границы и безопасный запуск

Условия только выбирают кодовые ветки; сами по себе они не проверяют, что пользовательский ввод имеет ожидаемый тип или безопасен. При нескольких истинных условиях в цепочке выполняется первая подходящая ветка. Следи за отступами и тестируй границы условий.

## English

This is a short preview of branching, not a separate full chapter. The course continues with a complete lesson on conditions, loops, and functions.

### Goal

Trace how a program checks a condition and chooses an execution branch.

### Idea and mechanism

An if statement evaluates a condition that is true or false. If it is true, its block runs; elif checks another alternative when earlier conditions did not match; an optional else provides a fallback. In Python, indentation marks the blocks.

```python
temperature = -2
if temperature < 0:
    state = "ice"
elif temperature < 20:
    state = "cool"
else:
    state = "warm"
print(state)
```

When `temperature = -2`, the first check is true, so the program prints `ice`. The remaining branches in this chain are skipped.

### Explore and practise

Replace `-2` with `8` and `25` in turn. Trace which first condition matches and predict the output. Expected results: `-2 → "ice", 8 → "cool", 25 → "warm"`. Then move the `temperature < 20` check before `temperature < 0`: `-2` will match the first branch and produce `cool`. Explain why the order changed the result.

### Question

Which value does the first branch assign when temperature = -2?

### Options

- "ice"
- "cool"
- "warm"

### Answer

1

### Explanation

The condition temperature < 0 is true for -2, so the first branch runs and selects "ice"; later conditions are not checked.

### Limits and safe execution

Conditions choose code branches; they do not by themselves check that user input has the expected type or is safe. If several conditions in a chain are true, the first matching branch runs. Watch indentation and test boundary cases.

## Sources

- Python Software Foundation, [Python Tutorial §4.1: if Statements](https://docs.python.org/3/tutorial/controlflow.html#if-statements)

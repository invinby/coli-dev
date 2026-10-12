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

### Цель

Прослеживать, как программа проверяет условие и выбирает ветку выполнения.

### Идея и механизм

Условный оператор if вычисляет условие, которое даёт истину или ложь. Если оно истинно, выполняется соответствующий блок; elif проверяет следующую альтернативу, когда предыдущие условия не подошли; необязательный else задаёт запасной путь. В Python границы блоков задаются отступами.

В примере temperature = -2 первая проверка temperature < 0 истинна, поэтому выполняется ветка «ice», а остальные ветки пропускаются.

### Исследуй и потренируйся

Проследи по очереди значения -2, 8 и 25 в трёхветочном if/elif/else. Для каждого запиши, какое условие сработало первым и какое значение получит переменная. Затем измени порядок проверок и предскажи, изменится ли результат.

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

### Goal

Trace how a program checks a condition and chooses an execution branch.

### Idea and mechanism

An if statement evaluates a condition that is true or false. If it is true, its block runs; elif checks another alternative when earlier conditions did not match; an optional else provides a fallback. In Python, indentation marks the blocks.

In the example temperature = -2, the first check temperature < 0 is true, so the "ice" branch runs and later branches are skipped.

### Explore and practise

Trace -2, 8, and 25 through a three-branch if/elif/else. For each value, record which condition matches first and what value the variable receives. Then change the order of the checks and predict whether the result changes.

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

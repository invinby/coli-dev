---
subject: mathematics
lesson_id: mathematics.systems_of_linear_equations
level: intermediate
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 365
---

# Системы линейных уравнений: одна точка, нет пересечения или одна прямая / Linear Systems: One Intersection, None, or the Same Line

## Русский

### Цель

Определить, сколько решений имеет система двух линейных уравнений, и объяснить результат сложением уравнений.

### Идея и механизм

Решение системы — это пара `(x, y)`, которая одновременно удовлетворяет обоим уравнениям. Каждое уравнение с двумя переменными задаёт прямую. Поэтому две прямые могут пересечься в одной точке, не пересечься или совпасть.

Возьмём `2x + y = 11` и `x − y = 1`. Складываем левые и правые части: `3x = 12`, значит `x = 4`. Подстановка во второе уравнение даёт `y = 3`. Проверка в первом: `2·4 + 3 = 11`. Пара `(4, 3)` подходит сразу к обоим уравнениям.

Если после устранения переменной получается `0 = число, не равное нулю`, система несовместна. Это две параллельные прямые: общих точек нет. Если получается `0 = 0`, второе уравнение не добавило нового ограничения: прямые совпадают и решений бесконечно много.

### Исследуй и потренируйся

Выбери систему в тренажёре и сначала предскажи число решений. Затем сравни коэффициенты: для первого примера сложение убирает `y`; для параллельных прямых оно приводит к противоречию; для совпадающих прямых — к тождеству. Не считай только одну координату готовым ответом: подставь найденную пару в оба исходных уравнения.

### Вопрос

Что означает результат `0 = 0` после сложения кратных уравнений системы?

### Варианты

- У системы нет решений.
- У системы одна точка пересечения.
- Уравнения задают одну прямую, поэтому решений бесконечно много.

### Ответ

3

### Разбор

Тождество `0 = 0` означает, что после устранения переменной не осталось противоречия или нового ограничения. В этой системе уравнения описывают одну и ту же прямую, и каждая точка на ней удовлетворяет обоим уравнениям.

### Границы модели

Тренажёр показывает три тщательно подобранных примера и не разбирает автоматически произвольный ввод, дробные коэффициенты, системы с тремя переменными или округление графиков. Для каждой новой задачи выпиши обе исходные строки, выполни допустимую операцию над ними и проверь найденную пару в исходной системе.

## English

### Goal

Classify a two-equation linear system and explain its result using elimination by addition.

### Idea and mechanism

A solution is a pair `(x, y)` that satisfies both equations at once. Each linear equation in two variables describes a line. Two lines can intersect once, never intersect, or coincide.

Consider `2x + y = 11` and `x − y = 1`. Add the left and right sides: `3x = 12`, so `x = 4`. Substituting into the second equation gives `y = 3`. Check the first: `2·4 + 3 = 11`. The pair `(4, 3)` satisfies both equations.

If elimination gives `0 = a nonzero number`, the system is inconsistent. The lines are parallel and have no common point. If it gives `0 = 0`, the second equation added no new restriction: both equations describe the same line, so infinitely many points are solutions.

### Explore and practise

Choose a system in the trainer and predict its number of solutions first. Then compare the coefficients: adding removes `y` in the first example, produces a contradiction for parallel lines, and produces an identity for coincident lines. Do not stop after finding one coordinate; substitute the ordered pair into both original equations.

### Question

What does `0 = 0` after adding multiples of the equations tell you?

### Options

- The system has no solution.
- The system has one intersection.
- Both equations describe the same line, so there are infinitely many solutions.

### Answer

3

### Explanation

The identity `0 = 0` is neither a contradiction nor a new restriction. In this system, both equations describe the same line, and every point on that line satisfies both equations.

### Limits and safe execution

The trainer shows three selected examples. It does not solve arbitrary learner input, fractional coefficients, three-variable systems, or graph-rounding errors. For a new problem, write both original rows, apply a valid row operation, and check any proposed pair in the original system.

## Sources

- OpenStax, *College Algebra 2e*, §7.1 “Systems of Linear Equations: Two Variables”, consulted 2026-10-06: <https://openstax.org/books/college-algebra-2e/pages/7-1-systems-of-linear-equations-two-variables>
- OpenStax textbooks use CC BY-NC-SA 4.0. This explanation is original and does not copy the textbook; the source monitor keeps this page metadata-only and does not cache it for RAG.

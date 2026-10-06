---
subject: mathematics
lesson_id: mathematics.rational_expressions_and_restrictions
level: intermediate
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 365
---

# Рациональные выражения: сокращай множители, сохраняй ограничения / Rational Expressions: Cancel Factors, Keep Restrictions

## Русский

### Цель

Раскладывать простое рациональное выражение на множители, сокращать только общие множители и сохранять запрещённые значения исходного знаменателя.

### Идея и механизм

Рассмотрим выражение `f(x) = (x² − 9)/(x − 3)`. До любых преобразований знаменатель показывает, что `x ≠ 3`. Разложим числитель как разность квадратов: `x² − 9 = (x − 3)(x + 3)`. Для допустимых `x` общий **множитель** `(x − 3)` сокращается, поэтому `f(x) = x + 3`, но только при сохранённом условии `x ≠ 3`.

Точка `x = 3` остаётся исключённой из исходной функции: в исходной дроби там деление на ноль. Упрощённая формула `x + 3` сама определена при `x = 3` и даёт 6, но это не возвращает исключённую точку в область исходной функции. Графически это выглядело бы как открытая точка `(3, 6)`. Равенство упрощённых выражений действует на общей допустимой области.

Сокращают множители, а не слагаемые: `((x − 3)(x + 3))/(x − 3)` можно сократить; `((x + 3) + 2)/(x + 3)` — нельзя сократить `x + 3` между частью суммы и знаменателем.

### Исследуй и потренируйся

Двигай `x` от −5 до 5. Сравни значения исходной дроби и `x + 3`. При `x = 3` исходная дробь недопустима, хотя упрощённая формула показывает число. Вернись к знаменателю и объясни, почему значение 6 не является ответом исходной функции в этой точке.

### Вопрос

Какое утверждение верно для `f(x) = (x² − 9)/(x − 3)` после разложения числителя и сокращения?

### Варианты

- `f(x) = x + 3` при всех вещественных `x`, включая 3.
- `f(x) = x + 3` при `x ≠ 3`; значение исходной функции при 3 не определено.
- Общий множитель нельзя сокращать, потому что после этого выражение меняет значение при любом `x`.

### Ответ

2

### Разбор

Первый вариант теряет исходное ограничение знаменателя. Третий путает множитель со слагаемым: для `x ≠ 3` сокращение общего множителя сохраняет значение дроби. Поэтому верен второй вариант.

### Границы модели

Тренажёр исследует один пример с линейным исключённым множителем и не решает произвольные рациональные выражения. Для каждого нового выражения сначала выпиши значения, обращающие исходный знаменатель в ноль, затем проверь все преобразования на этой области. При решении уравнений с дробями нужно дополнительно подставить найденные корни в исходное уравнение.

## English

### Goal

Factor a simple rational expression, cancel only common factors, and retain values excluded by the original denominator.

### Idea and mechanism

Consider `f(x) = (x² − 9)/(x − 3)`. Before any algebra, the denominator tells us `x ≠ 3`. Factor the numerator as a difference of squares: `x² − 9 = (x − 3)(x + 3)`. For allowed inputs, cancel the common **factor** `(x − 3)`, giving `f(x) = x + 3` while keeping the condition `x ≠ 3`.

The input `x = 3` remains excluded from the original function because its original denominator is zero. The simplified formula `x + 3` is defined at 3 and returns 6, but that does not put the excluded input back into the original function's domain. On a graph, this would appear as an open point at `(3, 6)`. The simplified expressions are equal on their shared allowed domain.

Cancel factors, not terms: `((x − 3)(x + 3))/(x − 3)` can be reduced; `((x + 3) + 2)/(x + 3)` cannot cancel `x + 3` between part of a sum and the denominator.

### Explore and practise

Move `x` from −5 to 5. Compare the original fraction with `x + 3`. At `x = 3`, the original fraction is undefined even though the reduced formula displays a number. Return to the denominator and explain why 6 is not a value of the original function at that input.

### Question

Which statement is correct after factoring and reducing `f(x) = (x² − 9)/(x − 3)`?

### Options

- `f(x) = x + 3` for every real `x`, including 3.
- `f(x) = x + 3` for `x ≠ 3`; the original function is undefined at 3.
- The common factor cannot be cancelled because that changes the fraction for every `x`.

### Answer

2

### Explanation

The first choice loses the original denominator restriction. The third confuses a factor with a term: for `x ≠ 3`, cancelling a common factor preserves the fraction's value. Therefore the second choice is correct.

### Limits

The trainer explores one example with a linear excluded factor; it does not simplify arbitrary rational expressions. For a new expression, first record inputs that make the original denominator zero, then keep that domain restriction through every transformation. When solving rational equations, also substitute candidate roots into the original equation.

## Sources

- OpenStax, *College Algebra 2e*, §1.6 “Rational Expressions” (consulted 2026-10-06): <https://openstax.org/books/college-algebra-2e/pages/1-6-rational-expressions>
- OpenStax, *College Algebra 2e*, §5.6 “Rational Functions” (consulted 2026-10-06): <https://openstax.org/books/college-algebra-2e/pages/5-6-rational-functions>
- OpenStax textbooks use CC BY-NC-SA 4.0; this lesson is a new explanation, not copied source text. The source monitor tracks metadata only and does not cache these pages for RAG.

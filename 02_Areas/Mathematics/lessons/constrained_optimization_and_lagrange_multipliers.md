---
subject: mathematics
lesson_id: mathematics.constrained_optimization_and_lagrange_multipliers
level: advanced
languages: ru, en
source_checked: 2026-10-08
source_review_interval_days: 365
---

# Оптимизация с ограничением и множители Лагранжа / Constrained Optimization and Lagrange Multipliers

## Русский

### Цель

Находить кандидатов на условный экстремум гладкой функции при одном гладком равенстве-ограничении, объяснять роль множителя Лагранжа и отдельно доказывать, какие кандидаты дают глобальный максимум или минимум.

### Идея и механизм

Пусть нужно исследовать `f(x, y)` при условии `g(x, y) = 0`. В регулярной точке условного локального экстремума, где `∇g ≠ 0`, градиенты целевой функции и ограничения параллельны:

`∇f(x, y) = λ∇g(x, y)`, одновременно с `g(x, y) = 0`.

Число `λ` показывает, во сколько раз градиент ограничения масштабирует градиент цели в найденной точке. Система находит необходимые кандидаты, но сама по себе не определяет их тип: нужно проверить допустимость и сравнить значения функции. Условия и стратегия следуют формулировке OpenStax *Calculus Volume 3*, §4.8, теорема 4.20.

Рассмотрим максимум `f(x, y) = xy` на единичной окружности `x² + y² = 1`. Здесь `g(x, y) = x² + y² − 1`, `∇f = (y, x)`, `∇g = (2x, 2y)`. Система Лагранжа имеет вид `y = 2λx`, `x = 2λy`, `x² + y² = 1`. Координаты не могут быть нулевыми, поэтому из первых двух равенств следует `x² = y²` и `x = y` либо `x = −y`.

При `x = y` получаются точки `(1/√2, 1/√2)` и `(−1/√2, −1/√2)` с `f = 1/2` и `λ = 1/2`. При `x = −y` получаются `(1/√2, −1/√2)` и `(−1/√2, 1/√2)` с `f = −1/2` и `λ = −1/2`. Поскольку окружность замкнута и ограничена, а `f` непрерывна, абсолютные экстремумы существуют; сравнение всех найденных кандидатов даёт глобальный максимум `1/2` и минимум `−1/2`.

### Исследуй и потренируйся

В лаборатории двигай точку по окружности ползунком или перетаскиванием. Окружность — допустимое множество, пунктирные диагонали показывают направления `x = y` и `x = −y`, где находятся стационарные точки. Сначала предскажи знак `xy` и наличие стационарности, затем сравни ответ с вычисленными координатами, значением цели и `λ`. Проверь четыре точки пересечения диагоналей с окружностью и объясни, почему две дают максимум, а две — минимум.

### Вопрос

Какая пара точек задаёт глобальные максимумы `xy` при `x² + y² = 1`?

### Варианты

- `(1/√2, −1/√2)` и `(−1/√2, 1/√2)`
- `(1/√2, 1/√2)` и `(−1/√2, −1/√2)`
- `(1, 0)` и `(0, 1)`

### Ответ

2

### Разбор

На единичной окружности точки с `x = y` имеют одинаковые знаки координат и дают `xy = 1/2`; точки с `x = −y` имеют противоположные знаки и дают `xy = −1/2`. Поэтому вторая пара достигает глобального максимума. Точки `(1, 0)` и `(0, 1)` допустимы, но дают `xy = 0` и не являются стационарными точками ограничения.

### Границы модели

Условие `∇f = λ∇g` является необходимым условием первого порядка только при гладком равенстве и регулярности `∇g ≠ 0`; оно не охватывает особые точки, где градиент ограничения равен нулю. Оно находит кандидатов, а не классифицирует их автоматически. Для неравенств, углов, границ и негладких ограничений требуются дополнительные условия и отдельная проверка. Интерактив показывает двумерный пример на окружности, а не универсальный решатель оптимизации.

## English

*(Английский)*

### Goal

Find candidates for constrained extrema of a smooth function under one smooth equality constraint, explain the role of a Lagrange multiplier, and separately justify which candidates are global maxima or minima.

### Idea and mechanism

Suppose we want to analyze `f(x, y)` subject to `g(x, y) = 0`. At a regular constrained local extremum where `∇g ≠ 0`, the objective and constraint gradients are parallel:

`∇f(x, y) = λ∇g(x, y)`, together with `g(x, y) = 0`.

The scalar `λ` tells how the constraint gradient scales the objective gradient at the candidate. The system finds necessary candidates but does not classify them by itself: feasibility and objective values must still be checked. The conditions and procedure follow OpenStax *Calculus Volume 3*, §4.8, Theorem 4.20.

Consider maximizing `f(x, y) = xy` on the unit circle `x² + y² = 1`. Here `g(x, y) = x² + y² − 1`, `∇f = (y, x)`, and `∇g = (2x, 2y)`. The Lagrange system is `y = 2λx`, `x = 2λy`, and `x² + y² = 1`. Neither coordinate can be zero, so the first two equations imply `x² = y²`, or `x = y` or `x = −y`.

When `x = y`, the points are `(1/√2, 1/√2)` and `(−1/√2, −1/√2)`, with `f = 1/2` and `λ = 1/2`. When `x = −y`, the points are `(1/√2, −1/√2)` and `(−1/√2, 1/√2)`, with `f = −1/2` and `λ = −1/2`. The circle is closed and bounded and `f` is continuous, so absolute extrema exist; comparing every candidate gives the global maximum `1/2` and minimum `−1/2`.

### Explore and practise

Move the point around the circle with the slider or by dragging it. The circle is the feasible set; dashed diagonals show `x = y` and `x = −y`, where the stationary points lie. First predict the sign of `xy` and whether the selected point is stationary, then compare with the displayed coordinates, objective value, and `λ`. Check the four intersections of the diagonals with the circle and explain why two are maxima and two are minima.

### Question

Which pair gives the global maxima of `xy` subject to `x² + y² = 1`?

### Options

- `(1/√2, −1/√2)` and `(−1/√2, 1/√2)`
- `(1/√2, 1/√2)` and `(−1/√2, −1/√2)`
- `(1, 0)` and `(0, 1)`

### Answer

2

### Explanation

On the unit circle, points with `x = y` have coordinates with the same sign and give `xy = 1/2`; points with `x = −y` have opposite signs and give `xy = −1/2`. The second pair therefore gives the global maximum. The points `(1, 0)` and `(0, 1)` are feasible but yield `xy = 0` and are not stationary points of the constraint.

### Limits

The condition `∇f = λ∇g` is a first-order necessary condition only for a smooth equality at a regular point with `∇g ≠ 0`; it does not cover singular points where the constraint gradient is zero. It identifies candidates and does not automatically classify them. Inequalities, corners, boundaries, and nonsmooth constraints require additional conditions and separate checks. This interactive is a two-dimensional circle example, not a general-purpose optimization solver.

## Sources

*(Источники)*

- OpenStax, *Calculus Volume 3*, §4.8 “Lagrange Multipliers” / «Множители Лагранжа» (Theorem 4.20): <https://openstax.org/books/calculus-volume-3/pages/4-8-lagrange-multipliers>
- OpenStax, *Calculus Volume 3*, §4.7 “Maxima/Minima Problems” / «Задачи на максимумы и минимумы» (Theorem 4.18): <https://openstax.org/books/calculus-volume-3/pages/4-7-maxima-minima-problems>

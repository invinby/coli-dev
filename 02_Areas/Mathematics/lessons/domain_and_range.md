---
subject: mathematics
lesson_id: mathematics.domain_and_range
level: foundations
languages: ru, en
source_checked: 2026-10-05
source_review_interval_days: 365
---

# Область определения и множество значений / Domain and Range

## Русский

### Цель

Для формулы находить допустимые реальные входы, определять возможные выходы и записывать границы интервалами.

### Идея и механизм

Область определения отвечает на вопрос «какие входы разрешены?», а множество значений — «какие выходы может дать правило?». Ограничения могут следовать из самой формулы или из смысла задачи.

Для вещественной функции f(x) = √(8 − x) подкоренное выражение должно быть неотрицательным: 8 − x ≥ 0, поэтому x ≤ 8. Область определения — (-∞, 8]. Квадратный корень не бывает отрицательным; при достаточно малом x выход растёт без верхней границы, значит множество значений — [0, ∞).

Контекст тоже ограничивает вход. Для поездки на такси расстояние не может быть отрицательным. Если рассматриваем только поездки до 4 км и цена C(k) = 2 + 3k, то 0 ≤ k ≤ 4, а стоимость меняется от 2 до 14: 2 ≤ C ≤ 14. Точки, где граница включена, отмечают квадратной скобкой; невключённую границу — круглой.

### Исследуй и потренируйся

В тренажёре переключай модели поездки, квадрата и корня, затем меняй N. Сверяй разрешённые входы и выходы с графиком. Для y = x² на [-N, N] проверь минимум в середине: область входа симметрична, но выходы начинаются с 0, а не с отрицательного числа.

Разбери g(x) = 1/(x − 3): знаменатель не может быть нулём, поэтому x ≠ 3; значение 0 функция также не принимает. Всегда проверяй отдельно, что допускает формула, что допускает контекст и какие выходы действительно достигаются.

### Вопрос

Какова область определения f(x) = √(8 − x) среди вещественных чисел?

### Варианты

- x ≥ 8
- x ≤ 8
- Все вещественные x

### Ответ

1

### Разбор

Подкоренное выражение должно быть неотрицательным: 8 − x ≥ 0. После переноса получаем x ≤ 8, поэтому интервал области определения — (-∞, 8].

### Границы модели

Здесь рассматриваются вещественные входы и выходы. В других числовых системах правила могут отличаться. Контекст может сделать математически допустимую формулу бессмысленной, а для сложной функции множество значений нельзя надёжно определить по одной формуле без анализа графика, знака, экстремумов или предельного поведения.

## English

### Goal

Find the allowed real inputs of a formula, determine its possible outputs, and express boundaries with interval notation.

### Idea and mechanism

The domain answers “which inputs are allowed?” The range answers “which outputs can the rule produce?” Restrictions may come from the formula itself or from the situation being modelled.

For the real-valued function f(x) = √(8 − x), the radicand must be non-negative: 8 − x ≥ 0, so x ≤ 8. Its domain is (-∞, 8]. A square root is never negative; as x decreases without bound, the output grows without an upper bound, so the range is [0, ∞).

Context can restrict inputs too. A taxi distance cannot be negative. If we consider rides up to 4 km and the fare is C(k) = 2 + 3k, then 0 ≤ k ≤ 4 and the fare runs from 2 to 14: 2 ≤ C ≤ 14. Use square brackets for included endpoints and parentheses for excluded endpoints.

### Explore and practise

In the interactive lab, switch between taxi, square, and square-root models, then change N. Compare allowed inputs and outputs with the graph. For y = x² on [-N, N], check the minimum at the middle: the input domain is symmetric, but the outputs start at 0 rather than a negative value.

Consider g(x) = 1/(x − 3): the denominator cannot be zero, so x ≠ 3; the function also never outputs 0. Check separately what the formula allows, what the context allows, and which outputs are actually reached.

### Question

What is the domain of f(x) = √(8 − x) over the real numbers?

### Options

- x ≥ 8
- x ≤ 8
- Every real x

### Answer

1

### Explanation

The radicand must be non-negative: 8 − x ≥ 0. Rearranging gives x ≤ 8, so the domain interval is (-∞, 8].

### Limits

This lesson uses real inputs and outputs. Other number systems may follow different rules. Context can make a mathematically allowed formula meaningless, and a complex range cannot be determined reliably from the formula alone without checking its graph, sign, extrema, or limiting behaviour.

## Sources

- OpenStax, *Algebra and Trigonometry 2e*, “Domain and Range”: <https://openstax.org/books/algebra-and-trigonometry-2e/pages/3-2-domain-and-range>

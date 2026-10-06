---
subject: mathematics
lesson_id: mathematics.rates_of_change_and_derivative
level: intermediate
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 180
---

# Производная как мгновенная скорость изменения / The Derivative as an Instantaneous Rate of Change

## Русский

### Цель

Объяснить производную в точке через предел наклонов секущих, вычислить её для `f(x)=x²` и связать наклон графика с единицами измерения скорости изменения.

### Идея и механизм

Средняя скорость изменения функции на отрезке от `x` до `x+h` — это наклон секущей:

`(f(x+h) − f(x)) / h`, где `h ≠ 0`.

Чтобы получить мгновенную скорость изменения в точке `x`, уменьшаем шаг `h` к нулю и ищем предел этих наклонов:

`f′(x) = lim(h→0) (f(x+h) − f(x)) / h`.

В частном случае `f(x)=x²`:

`((x+h)² − x²) / h = (2xh + h²) / h = 2x + h`.

При `h → 0` значение `2x+h` стремится к `2x`, поэтому `f′(x)=2x`. Например, в точке `x=3` наклон касательной равен `6`. Нельзя просто подставить `h=0` в дробь: сначала нужно упростить выражение при `h≠0`, а затем вычислить предел.

Если `s(t)` описывает положение в метрах, а `t` — время в секундах, то `s′(t)` измеряется в метрах в секунду. Единицы производной всегда зависят от единиц выходной величины и входной переменной.

### Исследуй и потренируйся

В тренажёре выбери точку `x`, затем меняй положительный шаг `h`. Для `f(x)=x²` наклон секущей равен `2x+h`, а наклон касательной — `2x`. Например, при `x=2` и `h=1` секущая имеет наклон `5`; при `h=0,1` — `4,1`; касательная в `x=2` имеет наклон `4`. Наблюдай, как секущая поворачивается к касательной при уменьшении `h`, не делая шаг равным нулю.

### Вопрос

Для `f(x)=x²` чему равна производная в точке `x=2`?

### Варианты

- `2`
- `4`
- `8`

### Ответ

2

### Разбор

Из определения получается `f′(x)=2x`. Поэтому `f′(2)=4`. Геометрически это наклон касательной к параболе в точке `(2,4)`.

### Границы модели

Производная существует не во всех точках. У излома, разрыва, острого пика или вертикальной касательной обычного конечного двустороннего наклона может не быть. Производная в точке описывает локальное изменение, а не гарантирует поведение функции далеко от этой точки. Для вычисленного наклона указывай единицы и область, где функция определена.

## English

### Goal

Explain a derivative at a point as the limit of secant slopes, find it for `f(x)=x²`, and connect graph slope to the units of a rate of change.

### Idea and mechanism

The average rate of change of a function from `x` to `x+h` is the secant slope:

`(f(x+h) − f(x)) / h`, where `h ≠ 0`.

To find the instantaneous rate of change at `x`, shrink the step `h` toward zero and take the limit of those slopes:

`f′(x) = lim(h→0) (f(x+h) − f(x)) / h`.

For `f(x)=x²`:

`((x+h)² − x²) / h = (2xh + h²) / h = 2x + h`.

As `h → 0`, `2x+h` approaches `2x`, so `f′(x)=2x`. At `x=3`, for example, the tangent slope is `6`. Do not substitute `h=0` into the fraction: first simplify while `h≠0`, then evaluate the limit.

If `s(t)` gives position in metres and `t` is time in seconds, then `s′(t)` is measured in metres per second. Derivative units depend on the units of the output and input variables.

### Explore and practise

Choose a point `x` in the trainer and vary the positive step `h`. For `f(x)=x²`, the secant slope is `2x+h`, while the tangent slope is `2x`. At `x=2`, a step of `h=1` gives secant slope `5`; `h=0.1` gives `4.1`; the tangent at `x=2` has slope `4`. Watch the secant turn toward the tangent as `h` shrinks, without setting the step to zero.

### Question

For `f(x)=x²`, what is the derivative at `x=2`?

### Options

- `2`
- `4`
- `8`

### Answer

2

### Explanation

The definition gives `f′(x)=2x`, so `f′(2)=4`. Geometrically, this is the tangent slope to the parabola at `(2,4)`.

### Limits

A derivative does not exist at every point. At a corner, discontinuity, sharp cusp, or vertical tangent, the usual finite two-sided slope may not exist. A derivative describes local change; it does not guarantee how the function behaves far from that point. Include units and the domain on which the function is defined.

## Sources

- OpenStax, *Calculus Volume 1*, [3.1 Defining the Derivative](https://openstax.org/books/calculus-volume-1/pages/3-1-defining-the-derivative) — derivative as the limit of secant slopes and instantaneous rate of change.
- OpenStax, *Calculus Volume 1*, [3.2 The Derivative as a Function](https://openstax.org/books/calculus-volume-1/pages/3-2-the-derivative-as-a-function) — derivative function, graph interpretation, and differentiability.

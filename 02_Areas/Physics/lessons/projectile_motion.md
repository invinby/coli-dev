---
subject: physics
lesson_id: physics.projectile_motion
level: intermediate
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 365
---

# Движение тела, брошенного под углом / Projectile Motion

## Русский

### Цель

Разделять движение по горизонтали и вертикали и предсказывать время полёта, дальность и максимальную высоту в идеальной модели.

### Идея и механизм

Выбираем оси: x — горизонтально, y — вверх. Если сопротивлением воздуха можно пренебречь, ускорение по горизонтали равно нулю, а вертикальное ускорение равно `−g`. Начальную скорость `v₀` раскладываем на компоненты: `vₓ = v₀ cos θ` и `vᵧ = v₀ sin θ`. Поэтому горизонтальная координата меняется равномерно, а вертикальная — как при постоянном ускорении:

`x(t) = v₀ cos θ · t`

`y(t) = v₀ sin θ · t − ½gt²`

При старте и приземлении на одном уровне время полёта равно `T = 2v₀ sin θ / g`, дальность — `R = v₀² sin(2θ) / g`, а максимальная высота — `H = v₀² sin² θ / (2g)`. Формулы дальности и времени зависят от одинаковой высоты старта и приземления. В тренажёре используется округлённое `g = 9,81 м/с²`; принятое стандартное значение NIST — `9,80665 м/с²`, а местное ускорение свободного падения меняется с условиями и местом.

### Пример

Пусть мяч запускают со скоростью `20 м/с` под углом `30°`, а `g = 9,81 м/с²`. Тогда `vₓ ≈ 17,3 м/с`, `vᵧ = 10 м/с`, `T ≈ 2,04 с`, `R ≈ 35,3 м`, `H ≈ 5,10 м`. Вертикальная скорость равна нулю только в верхней точке; само ускорение там остаётся направленным вниз.

### Исследуй и потренируйся

В лаборатории измени скорость и угол, затем двигай ползунок времени, чтобы увидеть положение тела на дуге. Включи сравнение углов `θ` и `90° − θ`: при одинаковой скорости и одинаковой высоте приземления идеальная модель даёт одинаковую дальность, но разную высоту вершины. До перемещения ползунка предскажи, где находится объект в середине полёта и как меняется вертикальная координата.

Практика: при `v₀ = 20 м/с` и `θ = 30°` найди начальную вертикальную компоненту. Ответ: `vᵧ = 20 sin 30° = 10 м/с` вверх.

### Вопрос

Какое ускорение действует на тело в верхней точке траектории, если сопротивлением воздуха пренебречь?

### Варианты

- Нулевое: скорость на мгновение горизонтальна.
- `9,81 м/с²` вниз: гравитация действует и в верхней точке.
- Направленное вперёд и растущее со скоростью.

### Ответ

1

### Разбор

В верхней точке вертикальная компонента скорости равна нулю, но ускорение свободного падения не исчезает. Оно остаётся направленным вниз с величиной примерно `9,81 м/с²`.

### Границы модели

Модель предполагает постоянное ускорение свободного падения, старт и посадку на одном уровне, точечное тело и отсутствие сопротивления воздуха, ветра и вращения. При заметном сопротивлении воздуха траектория перестаёт быть симметричной параболой, а дальность зависит от формы, размера и скорости тела. Для иной высоты посадки нужно решать вертикальное уравнение с соответствующим начальным и конечным уровнем.

## English

### Goal

Separate horizontal and vertical motion, then predict flight time, range, and maximum height in an ideal model.

### Idea and mechanism

Choose axes with x horizontal and y upward. When air resistance is negligible, horizontal acceleration is zero and vertical acceleration is `−g`. Resolve the launch velocity `v₀` into `vₓ = v₀ cos θ` and `vᵧ = v₀ sin θ`. Horizontal position changes uniformly, while vertical position follows constant-acceleration motion:

`x(t) = v₀ cos θ · t`

`y(t) = v₀ sin θ · t − ½gt²`

For launch and landing at the same height, flight time is `T = 2v₀ sin θ / g`, range is `R = v₀² sin(2θ) / g`, and maximum height is `H = v₀² sin² θ / (2g)`. The range and flight-time formulas rely on equal launch and landing heights.

### Example

Launch a ball at `20 m/s` and `30°`, with `g = 9.81 m/s²`. Then `vₓ ≈ 17.3 m/s`, `vᵧ = 10 m/s`, `T ≈ 2.04 s`, `R ≈ 35.3 m`, and `H ≈ 5.10 m`. Vertical velocity is zero only at the peak; acceleration there still points downward.

### Explore and practise

Change speed and angle in the lab, then move the time slider to locate the object on its arc. Compare `θ` with `90° − θ`: at equal launch speed and equal landing height, the ideal model gives equal ranges but different peak heights. Before moving the slider, predict the object's position halfway through the flight and how its vertical coordinate changes.

Practice: for `v₀ = 20 m/s` and `θ = 30°`, find the initial vertical component. Answer: `vᵧ = 20 sin 30° = 10 m/s` upward.

### Question

What acceleration acts on the object at the top of its path when air resistance is negligible?

### Options

- Zero, because velocity is momentarily horizontal.
- `9.81 m/s²` downward, because gravity still acts at the peak.
- Forward, increasing with the object's speed.

### Answer

1

### Explanation

At the peak, vertical velocity is zero, but gravitational acceleration does not disappear. It remains downward with magnitude about `9.81 m/s²`.

### Limits

The model assumes constant gravitational acceleration, equal launch and landing heights, a point object, and no air resistance, wind, or spin. With appreciable drag, the path is no longer a symmetric parabola and range depends on the object's shape, size, and speed. A different landing height requires solving the vertical equation with that endpoint. The lab uses rounded `g = 9.81 m/s²`; NIST's conventional standard value is `9.80665 m/s²`, while local free-fall acceleration varies with location and conditions.

## Sources

- OpenStax, *College Physics 2e*, [3.4 Projectile Motion](https://openstax.org/books/college-physics-2e/pages/3-4-projectile-motion) — official reference for component-wise motion, trajectory, range, and the assumptions behind the ideal projectile model. Lesson text and practice are original; no textbook wording, figure, or worked problem is copied. OpenStax uses CC BY-NC-SA terms; verify product distribution rights before reusing any page text or figures.
- National Institute of Standards and Technology (NIST), [Guide to the SI, Appendix B.9](https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9) — source for the conventional standard acceleration of free fall, `gₙ = 9.80665 m/s²`. NIST says its web information may be distributed or copied unless marked copyrighted and requests appropriate credit: [NIST copyrights and disclaimers](https://www.nist.gov/copyrights-disclaimers).

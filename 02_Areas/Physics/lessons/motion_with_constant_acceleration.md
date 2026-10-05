---
subject: physics
lesson_id: physics.motion_with_constant_acceleration
level: intermediate
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 365
---

# Движение с постоянным ускорением / Motion with Constant Acceleration

## Русский

### Цель

Связать равнодействующую силу и массу с ускорением, а затем предсказать скорость и перемещение за заданное время. Отличать знаковое перемещение от пройденного пути.

### Идея и механизм

Выбери ось и назови одно направление положительным. Для постоянной массы второй закон Ньютона даёт `a = F_net / m`. Если равнодействующая и масса не меняются, ускорение постоянно. При начальном положении `x₀`, скорости `v₀` и времени `t`:

- `v = v₀ + at`
- `x − x₀ = v₀t + ½at²`

Когда стартуем из покоя и считаем начальное положение нулём, остаётся `v = at` и `Δx = ½at²`. Знак `Δx` показывает направление относительно выбранной оси; он не равен длине траектории, если тело меняло направление.

**Пример.** Тело массой `3 кг` начинает из покоя. На него действует постоянная сила `−6 Н` в течение `2 с`. Тогда `a = −6/3 = −2 м/с²`, `v = −4 м/с`, `Δx = ½·(−2)·2² = −4 м`. Минус означает движение в сторону, которую мы выбрали отрицательной.

### Исследуй в тренажёре

В открытом опыте «Сила и движение» начни с `F = 6 Н`, `m = 3 кг` и сбрось опыт. Запусти его на 2 секунды и запиши `a`, `v` и `Δx`. Повтори с `m = 6 кг` при той же силе: ускорение и перемещение за 2 секунды должны уменьшиться вдвое. Теперь измени знак силы, оставив массу `3 кг`: направление скорости и перемещения должно поменяться. Для ручного исследования используй шаги по `0,1 с`.

### Проверь понимание

Тело начинает из покоя. На него действует постоянная сила `−6 Н`; масса равна `3 кг`. Где оно будет относительно начала через `2 с`?

### Варианты

- `4 м` в положительном направлении
- `4 м` в отрицательном направлении
- `8 м` в отрицательном направлении

### Ответ

2

### Разбор

`a = F/m = −2 м/с²`; значит `Δx = ½at² = ½·(−2)·4 = −4 м`. Это знаковое перемещение. В этой задаче тело не разворачивалось, поэтому пройденный путь равен `4 м`.

### Границы модели

Уравнения используют одну ось, ньютоновское приближение, инерциальную систему отсчёта, неизменные массу и равнодействующую. Тренажёр начинает из покоя, ограничен двумя секундами и игнорирует трение, столкновения и вращение; он иллюстрирует, а не моделирует общий движок тел. В реальном движении при меняющейся силе раздели процесс на интервалы или используй модель с переменным ускорением. Если скорость стала нулевой и ускорение направлено против начальной скорости, не продолжай применять формулу пути как модуль одного знакового перемещения через разворот.

## English

### Goal

Relate net force and mass to acceleration, then predict velocity and displacement over a chosen time. Distinguish signed displacement from distance travelled.

### Idea and mechanism

Choose an axis and define one direction as positive. For constant mass, Newton's second law gives `a = F_net / m`. If net force and mass stay constant, acceleration is constant. For initial position `x₀`, initial velocity `v₀`, and elapsed time `t`:

- `v = v₀ + at`
- `x − x₀ = v₀t + ½at²`

For a start from rest with the initial position set to zero, these become `v = at` and `Δx = ½at²`. The sign of `Δx` gives direction along the chosen axis; it is not the path length if an object reverses direction.

**Example.** A `3 kg` object starts from rest. A constant `−6 N` force acts for `2 s`. Then `a = −6/3 = −2 m/s²`, `v = −4 m/s`, and `Δx = ½·(−2)·2² = −4 m`. The minus sign means motion toward the direction chosen as negative.

### Explore the lab

In the Force and Motion experiment, begin with `F = 6 N`, `m = 3 kg`, and reset. Run for two seconds and record `a`, `v`, and `Δx`. Repeat with `m = 6 kg` and the same force: acceleration and displacement after two seconds should be halved. Now reverse the force sign while keeping the mass at `3 kg`; velocity and displacement should reverse direction. Use 0.1-second steps for a manual investigation.

### Check your understanding

An object starts from rest. A constant `−6 N` force acts on its `3 kg` mass. Where is it relative to its starting position after `2 s`?

### Options

- `4 m` in the positive direction
- `4 m` in the negative direction
- `8 m` in the negative direction

### Answer

2

### Explanation

`a = F/m = −2 m/s²`, so `Δx = ½at² = ½·(−2)·4 = −4 m`. This is signed displacement. The object does not reverse in this example, so its path length is `4 m`.

### Limits

These equations assume one axis, a Newtonian regime, an inertial frame, constant mass, and constant net force. The lab starts from rest, runs for at most two seconds, and ignores friction, collisions, and rotation; it illustrates the equations rather than simulating general rigid-body dynamics. For changing forces, divide the motion into intervals or use a variable-acceleration model. If velocity reaches zero while acceleration still opposes the initial velocity, do not treat total path length after reversal as the magnitude of one signed displacement.

## Sources

- OpenStax, *College Physics 2e*, §2.5, “Motion Equations for Constant Acceleration in One Dimension”: https://openstax.org/books/college-physics-2e/pages/2-5-motion-equations-for-constant-acceleration-in-one-dimension — reference for independent fact-checking of the constant-acceleration equations. Lesson wording and exercise are original; no textbook passage, figure, worked example, or assessment has been copied. OpenStax states that the book is CC BY-NC-SA and prohibits ingestion of its content into generative-AI offerings without prior written permission. Do not include the linked page body in AI/RAG ingestion unless rights have been cleared.

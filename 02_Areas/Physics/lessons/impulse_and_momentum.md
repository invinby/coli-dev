---
subject: physics
lesson_id: physics.impulse_and_momentum
level: foundations
languages: ru, en
source_checked: 2026-10-12
source_review_interval_days: 365
---

# Импульс и столкновения / Momentum and Collisions

## Русский

### Цель

Вычислить импульс движущегося тела, связать силу с изменением импульса и найти общую скорость тел после одномерного идеально неупругого столкновения.

### Идея и механизм

Импульс тела — векторная величина `p = m v`. Масса `m` положительна, а скорость `v` имеет знак выбранной оси; поэтому объект, движущийся влево, имеет отрицательные `v` и `p`, если вправо выбрано положительным направлением. Единица импульса — `кг·м/с`.

Импульс силы, или толчок, равен изменению импульса: `J = Δp = F_net Δt` для постоянной результирующей силы. В общем случае `J = ∫_{t_i}^{t_f} F_net(t) dt` — векторный интеграл результирующей силы по времени. Сильная сила за короткое время может дать то же изменение импульса, что меньшая сила за более долгий промежуток.

Для выбранной системы полный импульс сохраняется во время взаимодействия, если внешний импульс системы пренебрежимо мал. При идеально неупругом столкновении тела слипаются, и из сохранения импульса следует `m₁v₁ + m₂v₂ = (m₁ + m₂)v_f`. Если начальные скорости тел различаются, поступательная кинетическая энергия после слипания уменьшается и часть её может перейти во внутреннюю энергию, звук и деформацию. При одинаковых начальных скоростях её потеря равна нулю.

Пример: тележка `2 кг` движется вправо со скоростью `4 м/с`, а тележка `2 кг` — влево со скоростью `2 м/с`. До столкновения `p = 2·4 + 2·(−2) = 4 кг·м/с`. Если тележки слиплись, `v_f = 4/(2+2) = 1 м/с` вправо. Кинетическая энергия до столкновения равна `20 Дж`, после — `2 Дж`; `18 Дж` перешли в другие формы энергии в идеализированной модели.

### Исследуй и потренируйся

В лаборатории меняй массы и знаковые скорости. До столкновения предскажи направление общего движения, затем открой состояние «После». Проверь одновременно две вещи: сумма импульсов не изменилась, а кинетическая энергия после слипания меньше, если начальные скорости различаются. Если начальные скорости равны, кинетическая энергия не изменится. При равных массах и равных встречных скоростях итоговая скорость должна стать нулевой.

Практика: тележка `3 кг` движется вправо со скоростью `2 м/с`; тележка `1 кг` движется влево со скоростью `4 м/с`. Они слипаются. Найди общий импульс до столкновения и общую скорость после. Ответ: `p = 3·2 + 1·(−4) = 2 кг·м/с`; `v_f = 2/(3+1) = 0,5 м/с` вправо.

### Вопрос

Тележка массой `2 кг` движется вправо со скоростью `4 м/с`. Вторая тележка массой `2 кг` движется влево со скоростью `2 м/с`. После идеально неупругого столкновения они слипаются. Какова их общая скорость?

### Варианты

- `1 м/с` вправо
- `3 м/с` вправо
- `1 м/с` влево

### Ответ

1

### Разбор

Выбери вправо положительным направлением. Тогда `p_before = 2·4 + 2·(−2) = 4 кг·м/с`. После слипания масса равна `4 кг`, поэтому `v_f = p_before/4 = 1 м/с` вправо.

### Границы модели

Здесь рассматриваются одномерные классические тела с постоянными массами. Закон сохранения импульса относится к полной выбранной системе и требует, чтобы внешний импульс за время столкновения был пренебрежимо мал. Внутренняя кинетическая энергия при неупругом столкновении не сохраняется; полная энергия системы сохраняется с учётом других форм энергии. Реальное столкновение не обязательно приводит к полному слипанию.

## English

### Goal

Calculate an object's momentum, relate force to momentum change, and find the shared velocity after a one-dimensional perfectly inelastic collision.

### Idea and mechanism

Momentum is the vector quantity `p = m v`. Mass `m` is positive, while velocity `v` has a sign set by the chosen axis; an object moving left has negative `v` and `p` when right is positive. Momentum is measured in `kg·m/s`.

Impulse equals a change in momentum: `J = Δp = F_net Δt` for a constant net force. In general, `J = ∫_{t_i}^{t_f} F_net(t) dt`, the vector time integral of the net force. A large force acting briefly can produce the same momentum change as a smaller force acting for longer.

The total momentum of a chosen system is conserved during an interaction when the system's external impulse is negligible. In a perfectly inelastic collision, the objects stick together, so conservation of momentum gives `m₁v₁ + m₂v₂ = (m₁ + m₂)v_f`. If their initial velocities differ, their translational kinetic energy decreases and some can become internal energy, sound, and deformation. If their initial velocities are equal, there is no kinetic-energy loss.

Example: a `2 kg` cart moves right at `4 m/s`, while another `2 kg` cart moves left at `2 m/s`. Before impact, `p = 2·4 + 2·(−2) = 4 kg·m/s`. If they stick, `v_f = 4/(2+2) = 1 m/s` to the right. Kinetic energy is `20 J` before and `2 J` after; in this idealized model, `18 J` has become other forms of energy.

### Explore and practise

Change the masses and signed velocities in the lab. Predict the direction of the combined motion before switching to the “After” view. Check two things: total momentum stays the same, while kinetic energy after the carts stick is lower when their initial velocities differ. If their initial velocities are equal, kinetic energy is unchanged. With equal masses and equal opposite velocities, the final velocity should be zero.

Practice: a `3 kg` cart moves right at `2 m/s`; a `1 kg` cart moves left at `4 m/s`. They stick together. Find the initial total momentum and their final velocity. Answer: `p = 3·2 + 1·(−4) = 2 kg·m/s`; `v_f = 2/(3+1) = 0.5 m/s` to the right.

### Question

A `2 kg` cart moves right at `4 m/s`. A second `2 kg` cart moves left at `2 m/s`. They stick together in a perfectly inelastic collision. What is their shared velocity?

### Options

- `1 m/s` to the right
- `3 m/s` to the right
- `1 m/s` to the left

### Answer

1

### Explanation

Choose right as positive. Then `p_before = 2·4 + 2·(−2) = 4 kg·m/s`. After sticking, the combined mass is `4 kg`, so `v_f = p_before/4 = 1 m/s` to the right.

### Limits

This lesson uses one-dimensional classical objects with constant masses. Momentum conservation applies to the full chosen system and requires negligible external impulse during the collision. Internal kinetic energy is not conserved in an inelastic collision; total energy is conserved when other forms are included. A real collision does not necessarily make the objects stick completely.

## Sources

- OpenStax, *College Physics 2e*, [8.1 Linear Momentum and Force](https://openstax.org/books/college-physics-2e/pages/8-1-linear-momentum-and-force)
- OpenStax, *College Physics 2e*, [8.2 Impulse](https://openstax.org/books/college-physics-2e/pages/8-2-impulse)
- OpenStax, *College Physics 2e*, [8.5 Inelastic Collisions in One Dimension](https://openstax.org/books/college-physics-2e/pages/8-5-inelastic-collisions-in-one-dimension)
- OpenStax, *University Physics Volume 1*, [9.2 Impulse and Collisions](https://openstax.org/books/university-physics-volume-1/pages/9-2-impulse-and-collisions) (time-integral definition of impulse; source checked 2026-10-12)

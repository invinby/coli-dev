---
subject: mathematics
lesson_id: mathematics.functions_as_models
level: foundations
languages: ru, en
source_checked: 2026-10-05
source_review_interval_days: 365
---

# Функции как модели / Functions as Models

## Русский

### Цель

По контексту определить вход и выход, записать простую функцию и понять её график, область определения и множество значений.

### Идея и механизм

Функция — правило, которое каждому допустимому входу ставит в соответствие ровно один выход. Входы образуют область определения; возможные выходы — множество значений. Правило можно показать словами, таблицей, формулой или графиком. Это разные представления одной модели.

Пусть поездка на такси стоит 2 условные денежные единицы за подачу машины и ещё 3 за каждый километр. Если `k` — километры, а `C` — стоимость, то `C(k) = 2 + 3k`. Число 2 задаёт начальное значение, а коэффициент 3 показывает, насколько стоимость растёт на каждый километр.

При `k = 4`: `C(4) = 2 + 3·4 = 14`. Если расстояние измеряется неотрицательными километрами, область модели — `k ≥ 0`, а стоимость при этих допущениях не меньше 2. График — прямая, но физический смысл ограничивает нас правой частью графика.

### Исследуй и потренируйся

На интерактивном графике меняй начальное значение `b` и наклон `m` в формуле `y = mx + b`. Сначала предскажи, куда сдвинется прямая, затем проверь. Для каждой выбранной точки подставь `x` в формулу и сравни вычисление с координатой на графике.

Задача: для модели `y = 2x − 1` найди выход при `x = 3`. **Подсказка:** сначала умножь `x` на коэффициент, потом прибавь начальное значение. Ответ: `5`.

### Вопрос

По модели `C(k) = 2 + 3k`, сколько стоит поездка на 4 км?

### Варианты

- 12
- 14
- 20

### Ответ

2

### Разбор

`C(4) = 2 + 3 × 4 = 14`. Число 12 пропускает начальную плату, а 20 получается, если умножить на 4 всё выражение.

### Границы модели

Линейная модель предполагает неизменную цену за километр и отсутствие пробок, ожидания, налогов и минимальной стоимости поездки. Функция описывает выбранные допущения, а не гарантирует, что реальная система всегда им следует. Не подставляй входы вне разумной области контекста.

## English

### Goal

Identify an input and an output in a short context, write a simple function, and interpret its graph, domain, and range.

### Idea and mechanism

A function is a rule that assigns exactly one output to each allowed input. The allowed inputs form the domain; the possible outputs form the range. A rule can be represented in words, a table, a formula, or a graph. These are different views of the same model.

Suppose a taxi ride costs 2 currency units to start plus 3 units per kilometre. Let `k` be distance and `C` be cost: `C(k) = 2 + 3k`. The 2 is the starting value; 3 tells us how much the cost rises for each kilometre.

For `k = 4`, `C(4) = 2 + 3·4 = 14`. If distance is non-negative, the model domain is `k ≥ 0`; under these assumptions, cost is at least 2. The graph is a line, but the context limits us to its right-hand part.

### Explore and practise

On an interactive graph, change the starting value `b` and slope `m` in `y = mx + b`. Predict how the line moves, then check. For a point on the graph, substitute `x` into the formula and compare your result with the plotted coordinate.

Try `y = 2x − 1` at `x = 3`. **Hint:** multiply `x` by its coefficient, then add the starting value. Answer: `5`.

### Question

Using `C(k) = 2 + 3k`, what does a 4 km ride cost?

### Options

- 12
- 14
- 20

### Answer

2

### Explanation

`C(4) = 2 + 3 × 4 = 14`. The answer 12 misses the starting charge; 20 comes from multiplying the whole expression by 4.

### Limits

The linear model assumes a constant price per kilometre and ignores traffic, waiting time, taxes, and minimum fares. A function describes chosen assumptions; it does not guarantee that a real system always follows them. Do not use inputs outside the context's sensible domain.

## Sources

- OpenStax, *Algebra and Trigonometry 2e*, “Functions and Function Notation”: <https://openstax.org/books/algebra-and-trigonometry-2e/pages/3-1-functions-and-function-notation>
- OpenStax, *Algebra and Trigonometry 2e*, “Domain and Range”: <https://openstax.org/books/algebra-and-trigonometry-2e/pages/3-2-domain-and-range>

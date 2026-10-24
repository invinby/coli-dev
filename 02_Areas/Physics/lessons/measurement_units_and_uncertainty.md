---
subject: physics
lesson_id: physics.measurement_units_and_uncertainty
level: foundations
languages: ru, en
source_checked: 2026-10-07
source_review_interval_days: 365
---

# Измерения, единицы и неопределённость / Measurement, Units, and Uncertainty

## Русский

### Цель

Записывать измерение вместе с единицей и указанной неопределённостью, переводить обе величины в другую единицу и проверять размерность результата.

### Идея и механизм

Число без единицы часто не отвечает на физический вопрос. Запись `12,4 ± 0,2 см` сообщает оценку длины и выбранную абсолютную неопределённость. При переводе в метры умножай **и значение, и неопределённость** на точный коэффициент `0,01 м/см`: получишь `0,124 ± 0,002 м`. Относительная неопределённость при таком переводе не меняется: `0,2 / 12,4 ≈ 1,6 %`.

Для физической формулы сначала сравни размерности. Например, скорость — это длина, делённая на время: `м/с`; сложение `3 м + 2 с` не имеет смысла. Размерностная проверка ловит часть ошибок, но совпадение единиц само по себе не доказывает, что формула или измерение верны.

Неопределённость не равна автоматически половине деления линейки: на неё влияют инструмент, способ считывания и условия опыта. Нужно указать, как она была оценена. Здесь `±` — заданная пользователем величина для учебного сравнения; тренажёр не выводит статистический доверительный интервал и не измеряет предмет за тебя.

### Исследуй и потренируйся

Поставь в тренажёре `12,4 см` и `±0,2 см`. Сначала предскажи запись в метрах, затем сравни центр и ширину цветной полосы на шкале. Увеличивай неопределённость при неизменной длине: центр останется на месте, а полоса расширится. Измени саму длину при той же неопределённости: абсолютная неопределённость сохранится, а относительная изменится.

Практика: длина `25,0 ± 0,5 см`. Запиши её в метрах, вычисли относительную неопределённость и объясни, почему запись `0,250 ± 0,5 м` неверна. Ответ для самопроверки: `0,250 ± 0,005 м`; относительная неопределённость `2 %`.

### Вопрос

Длина записана как `12,4 ± 0,2 см`. Как правильно выразить ту же запись в метрах?

### Варианты

- `0,124 ± 0,002 м`
- `0,124 ± 0,2 м`
- `12,4 ± 0,002 м`

### Ответ

1

### Разбор

Префикс «санти» означает `10⁻²`. Значение и абсолютную неопределённость умножаем на `0,01 м/см`: `12,4 × 0,01 = 0,124 м`, `0,2 × 0,01 = 0,002 м`. Соотношение неопределённости и значения остаётся тем же.

### Границы модели

Тренажёр работает только с положительной длиной в сантиметрах и переводом в метры. Цветная полоса показывает арифметические границы «значение ± выбранная неопределённость», а не гарантированное положение истинной длины и не распределение вероятностей. Правила оценки неопределённости, коррелированные измерения, калибровка прибора и распространение неопределённости через сложные формулы требуют отдельного урока.

## English

### Goal

Report a measurement with its unit and stated uncertainty, convert both numbers to another unit, and check the dimensions of a result.

### Idea and mechanism

A number without a unit often does not answer a physical question. The notation `12.4 ± 0.2 cm` gives an estimate of a length and a chosen absolute uncertainty. To express it in metres, multiply **both the value and the uncertainty** by the exact factor `0.01 m/cm`: the result is `0.124 ± 0.002 m`. Relative uncertainty does not change under this conversion: `0.2 / 12.4 ≈ 1.6%`.

Before using a physical equation, compare dimensions. Speed has length divided by time, such as `m/s`; adding `3 m + 2 s` is not meaningful. A dimension check catches some errors, but matching units alone cannot prove an equation or a measurement is correct.

Uncertainty is not automatically half a ruler division: the instrument, reading method, and experimental conditions matter. State how it was estimated. Here `±` is an input chosen for practice; the lab does not derive a statistical confidence interval or measure an object for you.

### Explore and practise

Set the lab to `12.4 cm` and `±0.2 cm`. Predict the result in metres before looking at it, then compare the centre and width of the coloured band on the scale. Increase uncertainty while holding the length fixed: the centre stays put and the band widens. Change length while holding uncertainty fixed: absolute uncertainty stays the same, while relative uncertainty changes.

Try `25.0 ± 0.5 cm`. Write it in metres, calculate the relative uncertainty, and explain why `0.250 ± 0.5 m` is wrong. Check: `0.250 ± 0.005 m`; relative uncertainty is `2%`.

### Question

A length is reported as `12.4 ± 0.2 cm`. Which expression reports the same measurement in metres?

### Options

- `0.124 ± 0.002 m`
- `0.124 ± 0.2 m`
- `12.4 ± 0.002 m`

### Answer

1

### Explanation

The prefix centi means `10⁻²`. Multiply the value and its absolute uncertainty by `0.01 m/cm`: `12.4 × 0.01 = 0.124 m`, and `0.2 × 0.01 = 0.002 m`. Their ratio stays the same.

### Limits

The lab covers a positive length in centimetres and its conversion to metres. The coloured band shows the arithmetic endpoints “value ± chosen uncertainty,” not a guaranteed location of the true length or a probability distribution. Estimating uncertainty, correlated measurements, instrument calibration, and propagation through more complex equations require separate treatment.

## Sources

- OpenStax, *University Physics Volume 1*, [1.3 Unit Conversion](https://openstax.org/books/university-physics-volume-1/pages/1-3-unit-conversion) (exact centimetre-to-metre factor; source checked 2026-10-07).
- OpenStax, *University Physics Volume 1*, [1.6 Significant Figures](https://openstax.org/books/university-physics-volume-1/pages/1-6-significant-figures) (measurement uncertainty and relative uncertainty; source checked 2026-10-07). The lesson text is newly written; these pages remain source metadata and are not copied into the RAG text cache.

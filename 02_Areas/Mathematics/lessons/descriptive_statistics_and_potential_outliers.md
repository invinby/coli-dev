---
lesson_id: mathematics.descriptive_statistics_and_potential_outliers
subject: mathematics
language: ru-en
level: intermediate
languages: ru, en
source_checked: 2026-10-11
source_review_interval_days: 365
---

# Описание данных: центр, разброс и потенциальные выбросы / Describing data: center, spread, and potential outliers

## Русский

### Цель

Научиться сравнивать среднее и медиану, находить межквартильный размах и решать, требует ли крайнее значение дополнительной проверки.

### Идея и механизм

Сначала упорядочи данные. **Среднее арифметическое** — сумма всех значений, делённая на их количество. **Медиана** — середина упорядоченного набора; при чётном количестве это среднее двух центральных значений. Среднее использует величину каждого наблюдения и поэтому может сильно сдвигаться из-за одного далёкого значения. Медиана обычно устойчивее к такому сдвигу.

Для квартилей в этом уроке используй правило «медианы половин»: `Q1` — медиана нижней половины, `Q3` — медиана верхней половины. Межквартильный размах `IQR = Q3 − Q1` описывает разброс центральной половины данных. По правилу `1.5 × IQR` значение ниже `Q1 − 1.5 × IQR` или выше `Q3 + 1.5 × IQR` помечается как **потенциальный выброс** для дальнейшего исследования.

### Пример из практики

Пусть шесть датчиков записали `[4, 5, 5, 6, 6, 20]` условных единиц. Среднее равно `46 / 6 ≈ 7.67`, медиана — `(5 + 6) / 2 = 5.5`. По медианам половин `Q1 = 5`, `Q3 = 6`, значит `IQR = 1`. Верхняя граница равна `6 + 1.5 × 1 = 7.5`; значение `20` выше неё. Это сигнал проверить датчик, процедуру измерения и контекст — само правило не доказывает, что данные ошибочны, и не разрешает автоматически удалить наблюдение.

### Исследуй и потренируйся

В тренажёре передвинь крайнее значение от `6` до `24`. Наблюдай, как меняются среднее, медиана и границы `1.5 × IQR`. Затем предскажи: стало ли максимальное значение выше верхней границы? Вернись к примеру и объясни, почему медиана меняется меньше среднего.

### Вопрос

Для `[4, 5, 5, 6, 6, 20]` максимальное значение `20` выше верхней границы потенциального выброса?

### Варианты

- Нет
- Да

### Ответ

2

### Разбор

Медиана верхней половины `[6, 6, 20]` равна `Q3 = 6`, нижней — `Q1 = 5`. Поэтому `IQR = 1`, а верхняя граница равна `7.5`; `20 > 7.5`. Слово «потенциальный» важно: сначала изучи происхождение значения и метод измерения.

### Границы модели

Метка по `1.5 × IQR` — удобное правило поиска необычных значений, а не универсальный тест ошибки, редкости или опасности. Квартильные соглашения для наборов нечётного размера и конкретных программ могут отличаться; в тренажёре медиана общей середины исключается из обеих половин. Не удаляй наблюдение только из-за этой метки: проверяй источник, единицы, сбор данных и предметный контекст. Маленький набор также не позволяет уверенно описать всю популяцию.

## English

### Goal

Compare the mean and median, calculate the interquartile range, and decide whether an extreme value needs further investigation.

### Idea and mechanism

Start by ordering the data. The **arithmetic mean** is the sum of all values divided by their count. The **median** is the middle of the ordered values; with an even count, it is the mean of the two central values. The mean uses each observation's magnitude, so one distant value can move it substantially. The median is usually more resistant to that shift.

This lesson uses the **median-of-halves rule** for quartiles: `Q1` is the median of the lower half and `Q3` is the median of the upper half. The interquartile range, `IQR = Q3 − Q1`, describes the spread of the middle half. Under the `1.5 × IQR` rule, a value below `Q1 − 1.5 × IQR` or above `Q3 + 1.5 × IQR` is flagged as a **potential outlier** for investigation.

### Practical example

Suppose six sensors record `[4, 5, 5, 6, 6, 20]` arbitrary units. The mean is `46 / 6 ≈ 7.67`; the median is `(5 + 6) / 2 = 5.5`. The medians of the two halves give `Q1 = 5` and `Q3 = 6`, so `IQR = 1`. The upper fence is `6 + 1.5 × 1 = 7.5`, and `20` is above it. This is a reason to inspect the sensor, measurement procedure, and context. The rule does not prove the data is wrong and does not authorize automatic deletion.

### Explore and practise

Move the extreme value from `6` to `24` in the lab. Observe how the mean, median, and `1.5 × IQR` fences respond. Then predict whether the maximum is above the upper fence. Return to the example and explain why the median moves less than the mean.

### Question

For `[4, 5, 5, 6, 6, 20]`, is the maximum value `20` above the potential-outlier upper fence?

### Options

- No
- Yes

### Answer

2

### Explanation

The median of the upper half `[6, 6, 20]` is `Q3 = 6`, and the median of the lower half is `Q1 = 5`. Therefore `IQR = 1` and the upper fence is `7.5`; `20 > 7.5`. “Potential” matters: first investigate how the value was produced and measured.

### Limits

The `1.5 × IQR` flag is a useful screening rule, not a universal test of error, rarity, or danger. Quartile conventions for odd-sized data sets and specific software can differ; this lab excludes the overall median from both halves. Do not delete an observation solely because it is flagged: check the source, units, collection method, and subject context. A small data set also cannot describe an entire population with confidence.

## Sources

- OpenStax, *Introductory Statistics 2e*, §2.3 “Measures of the Location of the Data” (quartiles, IQR, potential-outlier fences): https://openstax.org/books/introductory-statistics-2e/pages/2-3-measures-of-the-location-of-the-data. Source checked 2026-10-11. OpenStax states this text is CC BY-NC-SA 4.0; this lesson uses original wording and an original exercise, not copied text or figures.
- OpenStax, *Introductory Statistics 2e*, §2.5 “Measures of the Center of the Data” (mean and median): https://openstax.org/books/introductory-statistics-2e/pages/2-5-measures-of-the-center-of-the-data. Source checked 2026-10-11.

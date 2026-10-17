# Functions as Models: source audit / «Функции как модели»: аудит источников

**Checked / Проверено:** 2026-10-12  
**Lesson / Урок:** `02_Areas/Mathematics/lessons/functions_as_models.md`  
**Scope / Объём:** RU/EN definitions, input/output, domain/range, the illustrative taxi model, slope-intercept notation, graph interpretation, arithmetic, and linked trainer claims. / Определения RU/EN, вход/выход, область определения/значений, условная модель поездки на такси, форма с наклоном и пересечением оси, чтение графика, арифметика и утверждения тренажёра.

## Findings / Результаты

- **Function / Функция:** OpenStax *Algebra and Trigonometry 2e* §3.1 defines a function as assigning exactly one output to each permitted input and identifies the domain and range as input and output sets. The lesson's RU/EN definitions preserve that distinction.
- **Domain, range, and graphs / Область определения, множество значений и график:** §3.2 treats the domain as allowed inputs, the range as outputs, and warns that a graph may continue beyond the visible window. The lesson's taxi example correctly restricts `k` to `k ≥ 0` and, for `C(k) = 2 + 3k`, gives `C(k) ≥ 2` under its stated assumptions.
- **Linear model / Линейная модель:** OpenStax *College Algebra 2e* §4.1 states `f(x) = mx + b`, with `m` as constant rate of change/slope and `b` as the value at `x = 0` and y-intercept. This directly supports the lesson's interactive `y = mx + b` controls and graph. The example `y = 2x − 1` at `x = 3` evaluates to `5`.
- **Bilingual parity / Согласованность RU/EN:** The two lesson versions give the same hypothetical taxi inputs, calculations, constraints, learner task, answer choices, and limitations. The numbers are a teaching example, not external fare data.
- **Limits and reuse / Ограничения и повторное использование:** The lesson correctly presents the taxi equation as an assumption rather than a claim about every real fare. This audit adds source metadata and does not copy textbook passages or put them into RAG; OpenStax remains metadata-only under the repository's current source policy.

## Official sources / Официальные источники

1. OpenStax, *Algebra and Trigonometry 2e*, [§3.1 “Functions and Function Notation”](https://openstax.org/books/algebra-and-trigonometry-2e/pages/3-1-functions-and-function-notation) — function definition, input/output, domain/range, representations.
2. OpenStax, *Algebra and Trigonometry 2e*, [§3.2 “Domain and Range”](https://openstax.org/books/algebra-and-trigonometry-2e/pages/3-2-domain-and-range) — graph extent and interpreting domain/range.
3. OpenStax, *College Algebra 2e*, [§4.1 “Linear Functions”](https://openstax.org/books/college-algebra-2e/pages/4-1-linear-functions) — slope-intercept form, slope, initial value, y-intercept, and graph of a linear function.

No copied assessment questions, textbook passages, or source-derived fare data were added. / Задания, фрагменты текста учебника и тарифные данные из источника не копировались.

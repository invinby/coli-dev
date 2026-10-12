# Projectile motion source audit / Аудит источников: движение тела, брошенного под углом

**Date / Дата:** 2026-10-12
**Scope / Объём:** Checked the RU/EN projectile-motion lesson, numerical example, ideal-model limits, citations, and the matching Swift model/verifier against official OpenStax and NIST references.
**Объём проверки:** Сверены RU/EN урок о движении тела, брошенного под углом, числовой пример, ограничения идеальной модели, ссылки и соответствующая Swift-модель с официальными источниками OpenStax и NIST.

## Findings / Результаты

**EN:** The component equations and assumptions are consistent with OpenStax *College Physics 2e* §3.4: horizontal and vertical motion can be treated independently when drag is negligible, with gravity downward; the equal-height range and flight-time formulas are explicitly restricted to that setup. The lesson correctly explains that vertical velocity is zero at the apex while acceleration remains downward, and that complementary angles have equal range but different peak heights under the ideal level-ground model. NIST's conventional standard acceleration of free fall is `9.80665 m/s²`; the lesson's `9.81 m/s²` is correctly presented as a rounded model value. At `20 m/s` and `30°`, the rounded results are `vₓ ≈ 17.3 m/s`, `vᵧ = 10 m/s`, `T ≈ 2.04 s`, `R ≈ 35.3 m`, and `H ≈ 5.10 m`.

**RU:** Формулы компонент и допущения согласуются с §3.4 *College Physics 2e* от OpenStax: при пренебрежимо малом сопротивлении воздуха горизонтальное и вертикальное движение рассматриваются независимо, а ускорение свободного падения направлено вниз; формулы дальности и времени полёта явно ограничены случаем одинаковой высоты старта и приземления. Урок правильно объясняет, что в верхней точке вертикальная скорость равна нулю, а ускорение остаётся направленным вниз, и что при идеальной модели на ровной поверхности дополнительные углы дают одинаковую дальность, но разную максимальную высоту. Принятое NIST стандартное ускорение свободного падения равно `9,80665 м/с²`; значение `9,81 м/с²` в уроке корректно подано как округление для модели. При `20 м/с` и `30°` округлённые результаты верны: `vₓ ≈ 17,3 м/с`, `vᵧ = 10 м/с`, `T ≈ 2,04 с`, `R ≈ 35,3 м`, `H ≈ 5,10 м`.

**EN:** One clarity gap was found: `x(t)` and `y(t)` omit initial-position terms, but the lesson had not stated that its origin is the launch point. The lesson now states `x₀ = y₀ = 0` and tells learners to add initial coordinates when another origin is used. This matches OpenStax's coordinate-system guidance. The app model launches from ground level and clamps the displayed trajectory to that level; this matches the lesson's deliberately narrow model rather than a general unequal-height trajectory.

**RU:** Найден пробел в ясности записи: в `x(t)` и `y(t)` отсутствуют начальные координаты, но раньше не было сказано, что начало отсчёта находится в точке запуска. Теперь урок явно задаёт `x₀ = y₀ = 0` и поясняет, что при другой начальной точке нужно добавить её координаты. Это соответствует рекомендациям OpenStax по выбору системы координат. Модель приложения запускает тело с уровня земли и ограничивает отображаемую траекторию этим уровнем; это соответствует узкой модели урока, а не общей задаче с разной высотой старта и приземления.

## Sources / Источники

- OpenStax, *College Physics 2e*, [§3.4 Projectile Motion](https://openstax.org/books/college-physics-2e/pages/3-4-projectile-motion) — independent components, coordinate origin, ideal-model assumptions, equal-level range, and complementary-angle behavior / независимые компоненты, начало координат, допущения модели, дальность на одном уровне и свойства дополнительных углов.
- NIST, [Guide to the SI, Appendix B.9](https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9) — conventional standard acceleration of free fall `gₙ = 9.80665 m/s²` / принятое стандартное ускорение свободного падения.

**Limits / Ограничения:** This audit checks one lesson and its formula model. It does not establish full-course accuracy, test the rendered SwiftUI screen on a Mac, or imply that RAG rewrites lesson text. OpenStax material remains a fact-check reference; the lesson uses original wording and figures.
Проверен один урок и связанная с ним модель формул. Это не аудит всего курса, не проверка отображения SwiftUI на Mac и не означает, что RAG переписывает текст урока. Материалы OpenStax остаются источником для сверки фактов; формулировки и иллюстрации урока оригинальные.

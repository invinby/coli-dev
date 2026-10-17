# Computational thinking: decomposition and test cases / Алгоритмическое мышление: разбиение задач и тест-кейсы

**Research date / Дата проверки:** 2026-10-16
**Repository snapshot / Состояние репозитория:** branch codex/ai-role-routing, commit 93d3082aa530b64b8926967e966db9aff15ac925
**Scope / Объём:** Editorial and source audit of the existing bilingual Programming Foundations lesson and its trainer, focused on extending the lesson past the maximum of two numbers. No lesson, app, or code files were changed; no code or tests were run.

## Findings / Выводы

**RU:** Текущий урок уже шире одного примера: после максимума двух чисел он разбирает среднее непустого списка, раскладывает вычисление на шаги и классифицирует обычный, граничный и недопустимый тесты. Тренажёр SwiftUI также содержит последовательность шагов для обеих задач и проверки примеров среднего. Следующее полезное расширение — не добавлять ещё одну случайную задачу, а показать, как задача об одном максимуме обобщается на список произвольной длины: сначала контракт, затем разбиение на проверяемые шаги, затем набор тестов, подобранных под контракт и поведение цикла.

**EN:** The current lesson already goes beyond one example: after the maximum of two numbers, it covers the mean of a non-empty list, decomposes the calculation into steps, and classifies typical, boundary, and invalid cases. The SwiftUI trainer also has ordered steps for both tasks and exercises for the mean examples. The most useful next extension is not another unrelated example, but showing how “choose the maximum” generalizes to a list of arbitrary length: state the contract, decompose it into checkable steps, then select tests from the contract and loop behavior.

### Current lesson evidence / Что сейчас есть

- **RU:** 02_Areas/Programming/lessons/computational_thinking.md sets a goal of specifying steps before choosing a language and checking typical and boundary behavior. Its first worked pseudocode selects the maximum of two numbers and explicitly calls out equality. Its second worked example defines a non-empty integer-list contract, breaks the mean calculation into a precondition, accumulation, division, and return, then gives expected outcomes for [2, 4, 6], [7], [], and [-2, 2].
- **EN:** 02_Areas/Programming/lessons/computational_thinking.md asks learners to specify steps before choosing a language and check typical and boundary behavior. Its first worked pseudocode selects the maximum of two numbers and explicitly covers equality. Its second example defines a non-empty integer-list contract, decomposes the mean calculation into a precondition, accumulation, division, and return, then gives expected outcomes for [2, 4, 6], [7], [], and [-2, 2].

- **RU:** Дорожная карта уже обещает разбиение задач на шаги, примеры, крайние случаи и критерии правильности. Тренажёр в macOS/ColiDev/App/LearningViews.swift позволяет собрать алгоритм максимума двух чисел, проследить условие и посмотреть тесты среднего. В просмотренной реализации нет таблицы «вход → ожидаемый результат → фактический результат» для максимума списка; runtime тренажёра этим аудитом не проверялся.
- **EN:** The curriculum already promises decomposition into steps, examples, edge cases, and correctness criteria. The trainer in macOS/ColiDev/App/LearningViews.swift lets learners assemble the two-number maximum, trace its condition, and inspect mean test cases. The reviewed implementation does not show an input/expected/actual-results table for a list maximum; trainer runtime was not checked.

## Authoritative source findings / Выводы из первичных источников

| Official source / Официальный источник | Claim supported / Подтверждаемое положение | Lesson implication / Следствие для урока |
|---|---|---|
| CSTA, 2026 PK–12 Computer Science Standards, Computational Thinking practices, pp. 30–31; Algorithmic Problem Solving, pp. 35–39 | **RU:** CT6 включает явные критерии успеха, ограничения и разбиение сложной задачи на подзадачи. CT9 требует систематически проверять и отлаживать правило-ориентированные программы, в частности генерировать тест-кейсы. Стандарт MS-ALG-PS-03 предлагает проверять данный алгоритм на заданных входах трассировкой или запуском и не требует формального доказательства. HS-ALG-PS-03 допускает простые тест-кейсы для оценки корректности, ясности и эффективности; формальные доказательства, Big O и анализ всех входов не требуются. **EN:** CT6 names success criteria, constraints, and decomposing complex problems into manageable subproblems. CT9 calls for systematic testing/debugging and generating test cases for rule-based programs. MS-ALG-PS-03 recommends tracing or running a given algorithm on specific inputs and does not require formal proof. HS-ALG-PS-03 allows simple test cases to evaluate correctness, clarity, and efficiency; formal proof, Big O, and exhaustive input analysis are outside its stated boundary. | **RU:** Сначала попросить ученика определить цель, допустимый ввод, результат и ограничение; затем разбить решение на шаги. Тесты связывать с контрактом и условием/циклом, показывая ожидаемый результат и трассировку. Объяснить, что удачный конечный набор тестов выявляет ошибки, но не доказывает универсальную правильность. **EN:** Have learners state the goal, valid inputs, output, and constraints before decomposing the solution. Tie each test to the contract and a branch/loop behavior, showing expected output and trace. Explain that a finite passing suite can find defects but does not prove universal correctness. |
| College Board, AP Computer Science Principles Exam | **RU:** В описании экзамена цель CRD-2.J сформулирована как определение входов и соответствующих ожидаемых результатов или поведений, которыми можно проверить корректность алгоритма/программы. **EN:** The exam page states CRD-2.J as identifying inputs and corresponding expected outputs or behaviors that can check an algorithm’s or program’s correctness. | **RU:** Учить записывать ожидаемый результат заранее, до запуска алгоритма; после запуска сравнивать с фактическим. Это сильнее, чем просто спросить, «работает ли пример». **EN:** Teach learners to write the expected result before running the algorithm, then compare it with the actual result. That is more concrete than merely asking whether an example “works.” |
| Python documentation, unittest — Unit testing framework | **RU:** Официальная документация определяет тест-кейс как проверку конкретного отклика на заданный набор входов; в простом примере assertEqual сверяет результат, а assertRaises — ожидаемое исключение. **EN:** The official docs define a test case as checking a specific response to a particular set of inputs; the basic example uses assertEqual for results and assertRaises for expected exceptions. | **RU:** После таблицы ручной проверки можно показать короткий необязательный мост к Python-тестам: каждый сценарий — отдельная проверка; ожидаемый результат задаётся явно. Не начинать с фреймворка до понимания контракта и псевдокода. **EN:** After the manual test table, an optional bridge can turn each scenario into a Python test with an explicit expected result. Do not introduce the framework before learners understand the contract and pseudocode. |

**Standards note / Примечание о стандартах:** CSTA’s 2026 standards are now published. They supersede use of the 2017 code 2-AP-17 as the current reference; cite the 2026 practices and standard IDs above instead. This audit recommends a progression informed by CSTA; it does not claim CSTA has reviewed or certified ColiDev or this lesson.

## Recommended lesson extension / Рекомендуемое расширение урока

1. **RU — Контракт задачи:** «Найти наибольшее целое число в непустом списке». Уточнить: список может содержать отрицательные и одинаковые значения; пустой список не входит в допустимый ввод. Перед кодом договориться, что при пустом списке функция сообщает об ошибке.
   **EN — Task contract:** “Find the greatest integer in a non-empty list.” Clarify that values may be negative or repeated and an empty list is outside the valid input. Before coding, define that an empty list is reported as an error.

2. **RU — Разбиение:** начать с первого элемента как текущего максимума; пройти оставшиеся значения по одному; если значение больше текущего максимума — заменить его; после обхода вернуть максимум. Попросить объяснить, почему нельзя начинать с нуля: так сломается список, состоящий только из отрицательных чисел.
   **EN — Decomposition:** start with the first item as the current maximum; inspect each remaining value; replace the current maximum when the new value is greater; return it after the scan. Ask why starting at zero is wrong: it fails for an all-negative list.

3. **RU — Спланировать тесты до трассировки:** использовать небольшую таблицу ниже; к каждому сценарию привязать вопрос, на который он отвечает. Сначала ученик записывает ожидаемый ответ, затем вручную прослеживает шаги и отмечает фактический результат и «совпало / нет».
   **EN — Plan tests before tracing:** use the small table below and link each case to the question it answers. Learners write the expected result first, then trace the steps by hand and record actual result and pass/fail.

| Purpose / Назначение | Input / Ввод | Expected behavior / Ожидаемое поведение |
|---|---|---|
| Typical, maximum at end / Обычный случай, максимум в конце | [2, 4, 9] | 9 |
| Boundary, one valid item / Граница: один допустимый элемент | [7] | 7 |
| Negative values / Отрицательные числа | [-8, -2, -5] | -2 |
| Repeated maximum / Повтор максимума | [3, 9, 9] | 9 |
| Invalid, outside the contract / Недопустимый ввод вне контракта | [] | Explicit error, e.g. ValueError / Явная ошибка, например ValueError |

4. **RU — Найти и исправить дефект:** дать вариант, который начинает максимум с нуля, либо обновляет максимум только при неправильном условии; попросить ученика указать минимальный тест, который проявляет ошибку, объяснить причину и повторно прогнать все сценарии.
   **EN — Find and fix a defect:** provide a version that initializes the maximum to zero or uses an incorrect update condition. Ask learners to identify a minimal revealing case, explain the cause, and rerun the full set.

5. **RU — Перенести в Python после псевдокода:** один тест сначала выполнить вручную; затем показать функцию и по желанию один-два теста unittest. Сохранить двуязычный разбор, а значения в таблице оставить одинаковыми в обеих версиях языка.
   **EN — Translate to Python after pseudocode:** run one test by hand first, then show the function and optionally one or two unittest checks. Keep the explanation bilingual and use the same table values in both language versions.

## Limits / Ограничения

**RU:** Рекомендованная матрица тестов — педагогическое предложение на основе контракта и типов поведения алгоритма; это не предписанный стандартом обязательный набор и не доказательство для всех списков. Отчёт не менял урок и тренажёр, не проверял локализацию экрана на Mac, автоматическую генерацию учебных материалов, исполнение примеров или фактический рантайм. Ссылки на стандарты не означают сертификацию продукта.

**EN:** The proposed test matrix is a pedagogical recommendation derived from the contract and algorithm behavior; it is not a mandated standards checklist and does not prove correctness for every list. This report did not edit the lesson or trainer, inspect Mac localization, validate automatic lesson generation, execute examples, or verify runtime behavior. Citing standards does not imply product certification.

## Sources / Источники

1. Computer Science Teachers Association, **2026 CSTA PK–12 Computer Science Standards** (official full PDF; relevant sections: Computational Thinking, pp. 30–31; Algorithms & Design, pp. 35–39; current revision and license information). [Official PDF](https://csteachers.org/2026-csta-pk-12-computer-science-standards/) · [Standards portal](https://csteachers.org/pk12standards/)
2. College Board, **AP Computer Science Principles Exam** (official exam page; learning objective CRD-2.J: inputs and corresponding expected outputs/behaviors for checking correctness). [Official page](https://apcentral.collegeboard.org/courses/ap-computer-science-principles/exam?course=556)
3. Python Software Foundation, **unittest — Unit testing framework** (official Python 3 documentation; test-case definition, assertEqual, assertRaises). [Official documentation](https://docs.python.org/3/library/unittest.html)

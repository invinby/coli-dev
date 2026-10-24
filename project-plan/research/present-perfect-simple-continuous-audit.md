# Present Perfect Simple and Continuous: source audit / Аудит источников Present Perfect Simple и Continuous

**Checked / Проверено:** 2026-10-14  
**Lesson / Урок:** `english.present_perfect_simple_continuous`  
**Outcome / Результат:** the answer key is correct; clarify the boundary between an activity that is continuing, one that has recently stopped, and a counted task that is still unfinished. / ключ ответа верный; уточнить различие между продолжающимся, недавно закончившимся действием и подсчитанной задачей, которая ещё не завершена.

## Sources reviewed / Проверенные источники

- British Council LearnEnglish, [Present perfect simple and continuous (B1–B2)](https://learnenglish.britishcouncil.org/free-resources/grammar/b1-b2/present-perfect-simple-continuous). Reviewed the explanation of result versus activity, quantity, duration, continuing or repeated actions, and evidence of recent activity.
- British Council LearnEnglish, [Present perfect](https://learnenglish.britishcouncil.org/free-resources/grammar/english-grammar-reference/present-perfect). Reviewed the present-perfect-continuous section on stative verbs and the warning against present perfect with finished past-time expressions.

## Findings / Выводы

### Form, focus, and examples / Формы, фокус и примеры

**RU:** Утверждения о формах `have/has + past participle` и `have/has + been + verb-ing` верны. British Council описывает Simple как форму, обычно выделяющую результат, а Continuous — деятельность; количество обычно связано с вопросом «сколько», длительность — с «как долго». Примеры `three chapters`, `for two hours`, `for` как промежуток и `since` как начальная точка корректны. `For` и `since` сами по себе не выбирают время. Пример о недавно совершавшейся деятельности подтверждён основным источником.

**EN:** The forms `have/has + past participle` and `have/has + been + verb-ing` are correct. British Council describes the simple form as usually foregrounding a result and the continuous form as focusing on activity; quantity commonly answers “how many,” while duration answers “how long.” The examples with `three chapters`, `for two hours`, `for` as a period, and `since` as a starting point are sound. `For` and `since` do not select a tense by themselves. The main source also supports describing recent activity.

### Counted work and the quiz / Подсчёт результата и вопрос

**RU:** Ответ `has read` верный: вопрос просит количество уже прочитанных глав. В официальном разборе British Council `I've been reading three books` обычно означает, что чтение ещё не завершено; поэтому вариант с Continuous здесь не подчёркивает требуемый законченный результат. Оговорка в уроке не утверждает, что Continuous всегда означает незавершённость.

**EN:** `Has read` is the correct answer because the question asks for the number of chapters already read. British Council's official explanation says that `I've been reading three books` normally suggests the reading is not complete, so the continuous option does not foreground the completed result requested here. The lesson caveat does not claim that the continuous form always means an unfinished action.

### Required clarification / Нужное уточнение

**RU:** В прежней формулировке Continuous объяснялся главным образом как длительность или текущий процесс. Уточнено, что действие может продолжаться или недавно завершиться, оставив заметный сейчас след; сама форма не всегда определяет завершённость. Сохранены уже верные ограничения про глаголы состояния и законченные моменты прошлого; для них в урок добавлена вторая официальная ссылка British Council.

**EN:** The earlier wording described the continuous form mainly through duration or an ongoing process. It now clarifies that an activity may still be happening or may have stopped recently while leaving present evidence; the form alone does not always establish completion. The existing caveats about stative verbs and finished past times remain, and a second official British Council reference was added to support them.

## Scope and limits / Объём и ограничения

**RU:** Проверен текст урока, его один вопрос с ключом и заявленные грамматические правила. Этот аудит не доказывает полноту всего курса английской грамматики и не заменяет ручную проверку интерфейса и сохранения результата на Mac. Из страниц British Council взяты ссылки для сверки; их учебные упражнения и тексты в ColiDev не копировались.

**EN:** This audit covers the lesson text, its single answer-keyed question, and its stated grammar rules. It does not establish completeness of the full English grammar course and does not replace hands-on Mac checks of the interface and saved results. British Council pages are cited as references; their exercises and lesson text were not copied into ColiDev.

## Local verification / Локальная проверка

**RU:** `python 01_Projects/curriculum_routes.py 02_Areas` прошёл: 6 предметов, 18 уровней и 53 подключённых урока разрешаются в двуязычное содержимое с вопросами, разборами, ограничениями и HTTPS-ссылками. `python -m pytest 01_Projects/test_curriculum_routes.py 01_Projects/test_knowledge_index.py -q` — 65 passed. Эти проверки подтверждают структуру маршрутов и поведение локального индекса, а не фактическое освоение темы пользователем.

**EN:** `python 01_Projects/curriculum_routes.py 02_Areas` passed: all 6 subjects, 18 levels, and 53 linked lessons resolve to bilingual content with questions, explanations, limits, and HTTPS references. `python -m pytest 01_Projects/test_curriculum_routes.py 01_Projects/test_knowledge_index.py -q` — 65 passed. These checks verify route structure and local-index behavior, not the learner's actual mastery.

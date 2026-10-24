---
subject: programming
lesson_id: programming.sql_transactions
level: intermediate
languages: ru, en
source_checked: 2026-10-13
source_review_interval_days: 90
---

# SQL-транзакции и целостность данных / SQL Transactions and Data Integrity

## Русский

### Цель

Спроектировать простую таблицу с ограничениями, выбрать и отфильтровать строки запросом `SELECT`, понять роль индекса и объяснить, как транзакция сохраняет или отменяет связанные изменения.

### Идея и механизм

В реляционной базе таблица задаёт форму записей, запрос выбирает нужные строки, а индекс может помочь поиску. Если несколько изменений должны сохраниться как одна операция, их объединяют транзакцией. Ниже разберём эти части на небольшой учебной модели.

### Схема задаёт правила

Перед SQL-запросами опиши, какие данные хранятся в строке и что нельзя принимать. В учебной таблице одна строка хранит длительность занятия и его тему:

```sql
CREATE TABLE study_sessions (
    id INTEGER PRIMARY KEY,
    topic TEXT NOT NULL,
    minutes INTEGER NOT NULL CHECK (minutes >= 0)
);
```

`PRIMARY KEY` различает записи, `NOT NULL` требует значение, а `CHECK` отвергает отрицательную длительность. `NOT NULL` нужен отдельно: в SQLite условие `CHECK`, которое вычислилось в `NULL`, само по себе не считается нарушением. Это пример для SQLite; детали типов и ограничений отличаются в других СУБД.

### SELECT: выбрать, отфильтровать, упорядочить

Запрос ниже возвращает только тему и длительность, оставляет занятия от 30 минут и сортирует их от длинных к коротким:

```sql
SELECT topic, minutes
FROM study_sessions
WHERE minutes >= 30
ORDER BY minutes DESC;
```

На учебных данных ожидаемый результат: `SQLite | 50`, затем `while | 35`. Для чтения запроса удобно мысленно пройти `FROM` → `WHERE` → список `SELECT` → `ORDER BY`; документация SQLite описывает этот порядок как объяснительную модель, а не обязательный алгоритм выполнения движком.

### Индекс помогает искать, но имеет цену

```sql
CREATE INDEX idx_study_sessions_minutes
ON study_sessions(minutes);
```

Индекс хранит упорядоченный путь от значений `minutes` к соответствующим строкам. Он может помочь повторяющемуся фильтру по длительности на достаточно больших данных, но не меняет правильный результат запроса и не гарантирует ускорение: планировщик может предпочесть просмотр всей маленькой таблицы. Индекс занимает место и должен обновляться при изменениях строк, поэтому создавай его под реальный запрос и проверяй план выполнения.

### Транзакция объединяет связанные изменения

Банковский перевод — одна логическая операция из двух изменений: уменьшить один счёт и увеличить другой. Если программа остановится между ними и сохранит только первое изменение, деньги «исчезнут». Транзакция задаёт границу работы: начать, внести согласованные изменения, затем выполнить `COMMIT` или `ROLLBACK`.

```sql
BEGIN;
UPDATE accounts SET balance = balance - 30 WHERE id = 1;
UPDATE accounts SET balance = balance + 30 WHERE id = 2;
COMMIT;
```

До `COMMIT` изменения относятся к незавершённой транзакции; при ошибке приложение может отменить её через `ROLLBACK`. В учебной модели исходные сохранённые балансы — 80 и 20, перевод — 30. Перед фиксацией временный дебет уменьшает один счёт; после второго изменения сумма снова равна 100. `COMMIT` делает новую пару сохранённым состоянием.

### ACID без магии

- **Atomicity / Атомарность:** группа изменений подтверждается целиком или отменяется. Это не значит, что любая ошибка автоматически откатит всю транзакцию: поведение зависит от базы и ошибки.
- **Consistency / Согласованность:** транзакция и ограничения схемы должны сохранять заданные правила данных; база не угадывает правила предметной области за разработчика.
- **Isolation / Изоляция:** параллельные транзакции не должны наблюдать недопустимую смесь промежуточных состояний; точные гарантии задаёт СУБД и уровень изоляции.
- **Durability / Надёжность фиксации:** после успешной фиксации база должна сохранять подтверждённые данные согласно своим гарантиям хранения.

### Исследуй и потренируйся

В тренажёре сначала подбери ограничения для таблицы, затем запрос для фильтрации и сортировки и индекс для того же фильтра. Сравни результат до и после индекса: строки должны остаться теми же. После этого продвинь банковский перевод через `BEGIN`, дебет, кредит и `COMMIT`. Сравни рабочие значения с сохранёнными; при сбое до кредита `ROLLBACK` возвращает последнюю сохранённую пару. Тренажёр показывает фиксированные данные и состояния, не открывает настоящую базу и не запускает SQL.

Измени на бумаге сумму перевода на 120 при балансе 80. Опиши, какое предусловие надо проверить до дебета и почему одного `ROLLBACK` недостаточно для проверки бизнес-правил.

### Вопрос

В учебной модели дебет уже выполнен, кредит ещё нет, а соединение сообщает об ошибке. Какой следующий шаг возвращает незавершённую транзакцию к прежней сохранённой паре счетов?

### Варианты

- `ROLLBACK`, пока транзакция остаётся открытой.
- `COMMIT`, чтобы сохранить промежуточное состояние.
- Начать второй `BEGIN` внутри текущей транзакции.

### Ответ

1

### Разбор

`ROLLBACK` отменяет незавершённую транзакцию и восстанавливает её сохранённое состояние. `COMMIT` подтвердил бы только те изменения, которые уже есть, а новый `BEGIN` не завершает текущую транзакцию. В production-коде после сбоя дополнительно нужно проверить состояние соединения и СУБД.

### Границы модели

Тренажёр показывает одну последовательную запись и упрощённые балансы; он не моделирует блокировки, конкурентных читателей, повтор попытки `COMMIT`, журналирование, отказ диска и разные уровни изоляции. Конкретные правила различаются между СУБД. В SQLite ручная транзакция обычно завершается ближайшим `COMMIT`/`ROLLBACK`, вложенный `BEGIN` не допускается (для вложенных точек используют savepoint), и одновременно допускается только одна активная пишущая транзакция. Защитные ограничения (`NOT NULL`, `CHECK`, внешние ключи), доступность средств, валюта, округление и авторизация перевода требуют отдельных проверок.

## English

### Goal

Design a simple table with constraints, select and filter rows with `SELECT`, understand an index, and explain how a transaction saves or cancels related changes.

### Idea and mechanism

In a relational database, a table defines the shape of records, a query selects the rows needed, and an index may help lookup. When several changes must persist as one operation, a transaction groups them. We will study these parts with a small teaching model.

### Schema states the rules

Before querying, describe which data each row stores and what values should be rejected. In this teaching table, each row stores a study topic and its duration:

```sql
CREATE TABLE study_sessions (
    id INTEGER PRIMARY KEY,
    topic TEXT NOT NULL,
    minutes INTEGER NOT NULL CHECK (minutes >= 0)
);
```

`PRIMARY KEY` identifies rows, `NOT NULL` requires a value, and `CHECK` rejects a negative duration. Keep `NOT NULL` separate: in SQLite, a `CHECK` expression that evaluates to `NULL` is not itself a constraint violation. This is a SQLite example; type and constraint details differ across database systems.

### SELECT: choose, filter, and order

This query returns only the topic and duration, keeps sessions of at least 30 minutes, and sorts from longest to shortest:

```sql
SELECT topic, minutes
FROM study_sessions
WHERE minutes >= 30
ORDER BY minutes DESC;
```

For the teaching data, the expected result is `SQLite | 50`, then `while | 35`. To read the query, mentally follow `FROM` → `WHERE` → the `SELECT` list → `ORDER BY`; SQLite documents this as an explanatory model, not as a required execution algorithm for the engine.

### An index can help lookup, at a cost

```sql
CREATE INDEX idx_study_sessions_minutes
ON study_sessions(minutes);
```

An index stores an ordered path from `minutes` values to matching rows. It can help repeated duration filters on sufficiently large data, but it does not change the correct query result and does not guarantee a speedup: the planner may prefer a full scan of a tiny table. An index uses storage and must be maintained as rows change, so create it for a real query and inspect the query plan.

### A transaction groups related changes

A bank transfer is one logical operation with two changes: subtract from one account and add to another. If a program stops between them and saves only the first change, money appears to disappear. A transaction marks the boundary: begin, apply related changes, then `COMMIT` or `ROLLBACK`.

```sql
BEGIN;
UPDATE accounts SET balance = balance - 30 WHERE id = 1;
UPDATE accounts SET balance = balance + 30 WHERE id = 2;
COMMIT;
```

Before `COMMIT`, changes belong to the unfinished transaction; after an error, an application can cancel it with `ROLLBACK`. The teaching model starts with saved balances of 80 and 20 and a transfer of 30. Before commit, the temporary debit lowers one account; after the second change, the total is 100 again. `COMMIT` makes the new pair the saved state.

### ACID in practice

- **Atomicity:** the group commits as a unit or is undone. This does not mean every error automatically rolls back the whole transaction; behavior depends on the database and error.
- **Consistency:** a transaction and schema constraints must preserve the data rules you define; a database cannot infer business rules for the developer.
- **Isolation:** concurrent transactions should not observe an invalid mixture of intermediate states; exact guarantees depend on the database and isolation level.
- **Durability:** after a successful commit, the database should retain confirmed data according to its storage guarantees.

### Explore and practise

In the trainer, first choose constraints for the table, then the query for filtering and sorting, and an index for that filter. Compare results before and after adding the index: the rows should stay the same. Then advance the bank transfer through `BEGIN`, debit, credit, and `COMMIT`. Compare working values with saved values; if failure happens before the credit, `ROLLBACK` restores the last saved pair. The trainer displays fixed data and states, opens no real database, and executes no SQL.

On paper, change the transfer amount to 120 when the source balance is 80. State which precondition to check before debiting and why `ROLLBACK` alone does not validate business rules.

### Question

In the teaching model, the debit happened but the credit did not, and the connection reports an error. What returns the unfinished transaction to the previous saved pair of accounts?

### Options

- `ROLLBACK` while the transaction is still open.
- `COMMIT` to save the intermediate state.
- Start a second `BEGIN` inside the current transaction.

### Answer

1

### Explanation

`ROLLBACK` undoes the unfinished transaction and restores its saved state. `COMMIT` would confirm the changes that currently exist, and another `BEGIN` does not finish the current transaction. Production code must also check the connection and database state after a failure.

### Limits and safe execution

The trainer shows one sequential writer and simplified balances; it does not model locks, concurrent readers, retrying a busy `COMMIT`, journaling, disk failure, or different isolation levels. Exact rules vary by database. In SQLite, a manual transaction normally ends with the next `COMMIT` or `ROLLBACK`, nested `BEGIN` is not allowed (savepoints serve nested scopes), and only one write transaction may be active at a time. Schema constraints (`NOT NULL`, `CHECK`, foreign keys), funds availability, currency, rounding, and transfer authorization need separate checks.

## Sources

- SQLite Documentation, “Transaction”: <https://www.sqlite.org/lang_transaction.html> — page updated 2026-02-18; checked 2026-10-13 / последнее обновление страницы 2026-02-18; проверено 2026-10-13.
- SQLite Documentation, “CREATE TABLE”: <https://www.sqlite.org/lang_createtable.html> — schema and constraints / схема и ограничения.
- SQLite Documentation, “SELECT”: <https://www.sqlite.org/lang_select.html> — selecting, filtering, and ordering result rows / выбор, фильтрация и сортировка строк результата.
- SQLite Documentation, “Query Planning”: <https://www.sqlite.org/queryplanner.html> — index use, query plans, and tradeoffs / использование индексов, планы запросов и компромиссы.
- SQLite, “Copyright”: <https://sqlite.org/copyright.html> — authors dedicate SQLite code and documentation to the public domain / авторы посвятили код и документацию SQLite общественному достоянию.

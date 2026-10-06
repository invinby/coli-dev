---
subject: programming
lesson_id: programming.sql_transactions
level: intermediate
languages: ru, en
source_checked: 2026-10-06
source_review_interval_days: 90
---

# SQL-транзакции и целостность данных / SQL Transactions and Data Integrity

## Русский

### Цель

Понять, как транзакция группирует связанные изменения, чтобы подтвердить их вместе или отменить незавершённый перевод.

### Идея и механизм

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

В пошаговой модели продвинь перевод через `BEGIN`, дебет, кредит и `COMMIT`. Сравни текущие значения с сохранёнными. Затем выбери сбой после дебета: пока транзакция открыта, данные отличаются, а `ROLLBACK` возвращает оба счёта к последней сохранённой паре. Симулятор не открывает настоящую базу и не запускает SQL.

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

Understand how a transaction groups related changes so they can be committed together or an incomplete transfer can be undone.

### Idea and mechanism

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

Advance the transfer through `BEGIN`, debit, credit, and `COMMIT` in the step-by-step model. Compare working balances with saved balances. Then choose a failure after the debit: while the transaction is open, the values differ; `ROLLBACK` returns both accounts to the last saved pair. The simulator does not open a real database or run SQL.

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

- SQLite Documentation, “Transaction”: <https://www.sqlite.org/lang_transaction.html> — page updated 2026-02-18; checked 2026-10-06 / последнее обновление страницы 2026-02-18; проверено 2026-10-06.

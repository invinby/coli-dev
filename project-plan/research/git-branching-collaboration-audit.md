# Git branching and collaboration practice — P1 / Практика веток Git и командной работы — P1

Date / Дата: 2026-10-13
Status / Статус: implemented in the working tree; Swift compilation and hands-on Mac acceptance are pending / реализовано в рабочем дереве; компиляция Swift и ручная приёмка на Mac ожидают проверки.

## Scope / Объём

**EN:** Extend the existing `programming.debugging_tests_and_git` lesson and its fixed-scenario SwiftUI trainer. Preserve the first six local-workflow item IDs. Add stable items for creating a feature branch, staging named files, reviewing the staged snapshot, committing on that branch, publishing it with an upstream, and opening a pull request for teammate review. The final state means “PR opened and awaiting checks/review,” not “merged.” The simulator runs no Git commands and makes no network requests.

**RU:** Расширить существующий урок `programming.debugging_tests_and_git` и его сценарный SwiftUI-тренажёр. Сохранить первые шесть ID локального рабочего цикла. Добавить постоянные ID для создания feature-ветки, подготовки выбранных файлов, проверки staging-снимка, коммита в этой ветке, публикации с upstream и открытия pull request для ревью коллегой. Финальное состояние означает «PR открыт и ожидает проверок/ревью», а не «изменения слиты». Симулятор не запускает Git-команды и не обращается к сети.

## Claims checked against primary sources / Утверждения сверены с первичными источниками

- `git switch -c <branch>` creates and switches to a branch; `-C` can reset an existing branch. See the official [git-switch manual](https://git-scm.com/docs/git-switch) and [Pro Git branching chapter](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell).
- `git push -u origin <branch>` sets an upstream for the branch being published. See the official [git-push manual](https://git-scm.com/docs/git-push).
- A pull request proposes changes between branches for review; it does not merge them automatically. Repository rules may require reviews or status checks before merge. See [GitHub Docs: Creating a pull request](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-a-pull-request) and [GitHub Docs: Writing code for a project](https://docs.github.com/en/pull-requests/concepts/writing-code-for-a-project).
- The five new exact source paths are metadata-only in the trusted-source registry. No text-reuse rights are asserted, so they are excluded from the RAG text cache.

**RU:** `git switch -c <branch>` создаёт ветку и переключает на неё; `-C` может сбросить уже существующую ветку. Это сверено с официальным [руководством git-switch](https://git-scm.com/docs/git-switch) и главой [Pro Git о ветвлении](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell). Команда `git push -u origin <branch>` задаёт upstream публикуемой ветке — см. официальный [справочник git-push](https://git-scm.com/docs/git-push). Pull request предлагает изменения между ветками для обсуждения и ревью, но сам ничего не сливает; правила репозитория могут требовать проверок и одобрений перед слиянием — см. [GitHub Docs: создание pull request](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-a-pull-request) и [GitHub Docs: написание кода для проекта](https://docs.github.com/en/pull-requests/concepts/writing-code-for-a-project). Пять новых точных страниц в реестре доверенных источников доступны только для проверки метаданных. Права на повторное использование текста не заявлены, поэтому страницы исключены из текстового RAG-кэша.

## Verification / Проверка

- Source-monitor regressions: the new official paths are accepted exactly, appear in lesson-reference extraction and the real Control Center inventory, reject unlisted paths, remain metadata-only, and do not push the current approved source list over its limit. The checks were observed failing before the allowlist/cap changes and passing after them.
- Full `01_Projects` backend suite: 534 passed.
- The Swift model verifier now checks all 12 unique steps, valid and invalid choice bounds, the exact branch/push/PR answer mappings, and each intermediate/final state. `swiftc` is not installed in the current Windows environment, so this verifier still requires the GitHub Actions macOS build.
- Physical Mac review remains open: validate visual layout, answer selection, feedback, saved attempt evidence, and RU/EN switching in the actual app.

**RU:** Регрессии монитора источников проверяют, что новые официальные страницы разрешены только по точным адресам, извлекаются из реального урока и инвентаря Control Center, неразрешённые пути отклоняются, страницы остаются metadata-only, а полный текущий список не превышает лимит. До изменения allowlist и лимита проверки наблюдаемо падали, после — проходят. Полный backend-набор: 534 passed. Swift-verifier расширен проверкой 12 уникальных шагов, допустимых и недопустимых индексов ответа, правильных команд для ветки/push/PR и промежуточных/финальных состояний. В текущей среде Windows нет `swiftc`, поэтому этот verifier ещё должен пройти сборку GitHub Actions для macOS. Ручная приёмка на физическом Mac остаётся открытой: проверить раскладку, выбор ответа, обратную связь, сохранение попыток и переключение RU/EN.

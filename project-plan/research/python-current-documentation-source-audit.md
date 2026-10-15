# Python direct-docs and source-monitor audit / Аудит прямых ссылок Python и мониторинга источников

**Reviewed / Проверено:** 2026-10-15
**Scope / Объём:** exact HTTPS paths cited by lessons, redirect behavior, source-monitor allowlist, and documented RAG reuse terms / точные HTTPS-пути из уроков, редиректы, allowlist монитора и условия повторного использования в RAG.

## Finding / Результат

**EN:** The monitor intentionally uses `follow_redirects=False`. Several cited Python documentation URLs under `/3/library/` and `/3.14/library/` now return HTTP 301 to `/builtins/`. Because the monitor does not follow redirects, these otherwise official citations could not be automatically checked or retrieved through their exact lesson URL. The current Python 3 documentation exposes the relevant built-in exceptions, functions, and types directly under `/3/builtins/`; the `sys` module remains under `/3/library/`.

**RU:** Монитор намеренно использует `follow_redirects=False`. Некоторые цитируемые адреса документации Python в `/3/library/` и `/3.14/library/` теперь отвечают HTTP 301 и перенаправляют на `/builtins/`. Поскольку монитор не следует редиректам, эти официальные источники нельзя было автоматически проверить и получить по точному адресу из урока. В текущей документации Python 3 нужные встроенные исключения, функции и типы доступны напрямую в `/3/builtins/`; модуль `sys` остаётся в `/3/library/`.

## Changes / Изменения

**EN:** Four bilingual Programming lessons now cite direct rolling Python 3 URLs for built-in functions, exceptions, types, and `sys`; their editorial source dates were refreshed on 2026-10-15. Exact paths were added to the trusted-source allowlist and Python RAG policy. The official Python docs license page says Python software and documentation are licensed under PSF License Version 2: [Python documentation license](https://docs.python.org/3/license.html). The policy adds only the specified paths and does not permit arbitrary URLs on `docs.python.org`.

**RU:** В четырёх двуязычных уроках Programming заменены редиректящие адреса на прямые rolling-ссылки Python 3 для встроенных функций, исключений, типов и `sys`; редакторские даты проверки обновлены 2026-10-15. Точные пути добавлены в allowlist доверенных источников и RAG policy Python. На официальной странице указано, что документация Python лицензирована по PSF License Version 2: [лицензия документации Python](https://docs.python.org/3/license.html). Разрешены только перечисленные пути, не любые адреса на `docs.python.org`.

**EN:** The exact Cambridge “Reporting clauses” page, three NHGRI glossary pages (`Gene`, `Phenotype`, `genotype`), NCBI Bookshelf `NBK26825`, and the MedlinePlus, OpenStax, and NIST terms/copyright pages are now monitored. The NHGRI glossary pages are RAG-eligible under NHGRI's public-domain policy unless the individual page marks third-party copyrighted material; attribution is retained. Cambridge grammar, the NCBI book page, and legal/terms pages are metadata-only. The publisher pages and legal notices are not copied into the RAG cache.

**RU:** Добавлены точные страницы Cambridge “Reporting clauses”, три глоссарные страницы NHGRI (`Gene`, `Phenotype`, `genotype`), NCBI Bookshelf `NBK26825`, а также страницы условий использования/авторских прав MedlinePlus, OpenStax и NIST. Страницы глоссария NHGRI разрешены для RAG согласно политике общественного достояния NHGRI, кроме возможных материалов сторонних правообладателей, помеченных на самой странице; атрибуция сохраняется. Грамматика Cambridge, страница книги NCBI и юридические страницы доступны только для метаданных. Тексты издателей и юридические условия не копируются в RAG-кэш.

## Source and network evidence / Источники и сетевая проверка

- [Current Python built-in exceptions](https://docs.python.org/3/builtins/exceptions.html), [built-in functions](https://docs.python.org/3/builtins/functions.html), and [built-in types](https://docs.python.org/3/builtins/stdtypes.html) — the current rolling Python 3 documentation routes. The pages currently identify the documentation as Python 3.15.0 / текущие rolling-страницы документации Python 3; сейчас страницы обозначены как Python 3.15.0.
- [NHGRI Gene](https://www.genome.gov/genetics-glossary/Gene), [Phenotype](https://www.genome.gov/genetics-glossary/Phenotype), and [Genotype](https://www.genome.gov/genetics-glossary/genotype); [NHGRI copyright policy](https://www.genome.gov/about-nhgri/Policies-Guidance/Copyright) says NHGRI website content is public domain unless otherwise indicated / страницы глоссария и политика авторских прав NHGRI.
- [Cambridge Reporting clauses](https://dictionary.cambridge.org/grammar/british-grammar/reporting-clauses) and [NCBI Bookshelf NBK26825](https://www.ncbi.nlm.nih.gov/books/NBK26825/) — lesson references kept as metadata-only / ссылки уроков, отслеживаются только метаданные.
- [MedlinePlus linking and using content](https://medlineplus.gov/about/using/usingcontent/), [OpenStax terms of use](https://openstax.org/terms-of-use), and [NIST copyrights and disclaimers](https://www.nist.gov/copyrights-disclaimers) — tracked as terms/license signals only / отслеживаются только как сигналы условий и лицензирования.

**EN:** On 2026-10-15, a direct HTTP check using the monitor's User-Agent and request headers returned `200` for the new Python, Cambridge, NHGRI, NCBI, and terms/copyright routes. The old Python built-in paths returned `301`. Separate following-redirect probes of the Royal Society and Wiley DOI destinations and the Company of Biologists JEB page ended at publisher endpoints returning `403`; these three article links remain cited but are not included in the automatic freshness allowlist. The existing PubMed record for the JEB study remains monitored. No publisher pages, full-text excerpts, or legal-page text were persisted.

**RU:** 2026-10-15 прямой HTTP-запрос с User-Agent и заголовками монитора вернул `200` для новых Python, Cambridge, NHGRI, NCBI и страниц условий/авторских прав. Старые пути встроенной документации Python вернули `301`. Отдельные запросы с переходом по редиректам для DOI Royal Society, Wiley и страницы JEB у Company of Biologists дошли до издательских адресов с ответом `403`; эти три ссылки на статьи сохранены в уроках, но не включены в allowlist автоматической проверки свежести. Запись PubMed для исследования JEB по-прежнему мониторируется. Страницы издателей, полные фрагменты статей и тексты юридических страниц не сохранялись.

## Verification / Проверка

**EN:** `python -m pytest 01_Projects/test_trusted_sources.py -q` — 73 passed. `python 01_Projects/curriculum_routes.py 02_Areas` — all 54 routes passed. The full backend suite passed: 544 tests. The trusted-source inventory has 139 approved URLs, 3 unsupported publisher references, and 0 sources omitted by the 150-item cap. GitHub Actions for this exact change are pending.

**RU:** `python -m pytest 01_Projects/test_trusted_sources.py -q` — 73 passed. `python 01_Projects/curriculum_routes.py 02_Areas` — прошли все 54 маршрута. Полный backend-набор прошёл: 544 теста. Реестр доверенных источников содержит 139 разрешённых URL, 3 неподдерживаемые ссылки издателей и 0 источников, пропущенных из-за лимита 150. GitHub Actions для этой точной версии ещё ожидается.

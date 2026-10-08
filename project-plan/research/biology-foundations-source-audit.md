# Biology foundations source audit / Аудит источников базовых уроков биологии

**Date / Дата:** 2026-10-08  
**Scope / Объём:** I reviewed all 12 RU/EN Markdown lessons in `02_Areas/Biology/lessons`, including their explanations, examples, answer keys, stated model limits, and cited reference pages. I checked the substantive claims against the cited official instructional/scientific sources and checked arithmetic in the worked examples.  
**Объём проверки:** Проверены все 12 русско-английских Markdown-уроков в `02_Areas/Biology/lessons`: объяснения, примеры, ключи ответов, заявленные ограничения моделей и приведённые источники. Содержательные утверждения сопоставлены с указанными официальными учебными и научными источниками; арифметика разобранных задач проверена.

## Overall result / Общий результат

**Finding (EN):** Most foundational mechanisms and worked answers are consistent with the cited sources; I found one concrete overgeneralization and one wording that can teach a misleading cause. Three lessons also make claims or use exact mappings that their current citations do not directly document. These are source-coverage gaps, not evidence that the claims are false. One additional citation points only to a chapter overview rather than to evidence for the lesson’s group-specific claims.  
**Результат (RU):** Большинство базовых механизмов и решений задач согласуется с указанными источниками; обнаружены одно конкретное чрезмерное обобщение и одна формулировка, которая может неверно объяснить причину. Ещё в трёх уроках есть утверждения или точные соответствия, которые текущие ссылки напрямую не подтверждают. Это пробелы в источниках, а не доказательство того, что утверждения неверны. Ещё одна ссылка ведёт только на обзор главы, а не на подтверждение утверждений о конкретных группах молекул.

**Scope limit (EN):** This is a content-and-source audit of the lesson files, not a runtime test of the app’s simulations, course routing, or current RAG index. No lesson file was changed.  
**Ограничение проверки (RU):** Это проверка содержания уроков и их источников, а не запуск симуляций в приложении, проверка маршрутизации курсов или актуального RAG-индекса. Файлы уроков не изменялись.

## Per-lesson findings / Выводы по урокам

### `biomolecules_and_building_blocks.md`

**Finding (EN):** The four macromolecule groups, amino-acid and nucleotide building units, condensation/hydrolysis summary, and triglyceride caveat are accurate at this level. The cited `3-introduction` URL is only the chapter overview; link the cited claim about carbohydrates, lipids, proteins, and nucleic acids directly to §§3.2–3.5 for traceable evidence.  
**Результат (RU):** Четыре группы макромолекул, аминокислоты и нуклеотиды как строительные компоненты, краткое описание конденсации/гидролиза и оговорка о триглицеридах изложены корректно для этого уровня. Указанная ссылка `3-introduction` ведёт только на обзор главы; утверждения об углеводах, липидах, белках и нуклеиновых кислотах лучше связать напрямую с §§3.2–3.5, чтобы источник можно было проверить.

**Sources / Источники:** [OpenStax Biology 2e §3.1, “Synthesis of Biological Macromolecules” / §3.1 «Синтез биологических макромолекул»](https://openstax.org/books/biology-2e/pages/3-1-synthesis-of-biological-macromolecules), [§3.2, “Carbohydrates” / §3.2 «Углеводы»](https://openstax.org/books/biology-2e/pages/3-2-carbohydrates), [§3.3, “Lipids” / §3.3 «Липиды»](https://openstax.org/books/biology-2e/pages/3-3-lipids), [§3.4, “Proteins” / §3.4 «Белки»](https://openstax.org/books/biology-2e/pages/3-4-proteins), [§3.5, “Nucleic Acids” / §3.5 «Нуклеиновые кислоты»](https://openstax.org/books/biology-2e/pages/3-5-nucleic-acids). The lesson’s existing chapter-overview URL / Изначальная ссылка урока на обзор главы: [OpenStax Chapter 3 overview / обзор главы 3](https://openstax.org/books/biology-2e/pages/3-introduction).

### `cell_cycle_and_differentiation.md`

**Finding (EN):** G₁/S/G₂, DNA replication in S phase, mitosis, chromatid separation, and cytokinesis are supported and correctly distinguished. The paragraph on differentiation, gene activity, and environmental signals is not supported by the two references currently listed; add a cell-differentiation/gene-expression source. No factual contradiction found.  
**Результат (RU):** G₁/S/G₂, репликация ДНК в S-фазе, митоз, расхождение хроматид и цитокинез подтверждаются источниками и правильно разделены. Абзац о дифференцировке, активности генов и сигналах среды не подтверждается двумя указанными ссылками; добавьте источник о дифференцировке клеток и экспрессии генов. Фактического противоречия не найдено.

**Sources / Источники:** [OpenStax Biology 2e §10.2, “The Cell Cycle” / §10.2 «Клеточный цикл»](https://openstax.org/books/biology-2e/pages/10-2-the-cell-cycle), [NHGRI, “Chromatid” / NHGRI, «Хроматида»](https://www.genome.gov/genetics-glossary/Chromatid). Suggested addition / Рекомендуемая дополнительная ссылка: [NCBI Bookshelf, “The Molecular Genetic Mechanisms That Create Specialized Cell Types” / NCBI Bookshelf, «Молекулярно-генетические механизмы формирования специализированных типов клеток»](https://www.ncbi.nlm.nih.gov/books/NBK26854/) and [NHGRI, “Gene Expression” / NHGRI, «Экспрессия генов»](https://www.genome.gov/genetics-glossary/Gene-Expression).

### `dna_genes_and_traits.md`

**Finding (EN):** The DNA bases and pairing, double helix, broad gene definition, non-protein-coding RNA products, and genotype/phenotype distinction are supported. The lesson appropriately rejects a one-gene/one-trait shortcut and identifies environmental influence; no concrete error found.  
**Результат (RU):** Азотистые основания ДНК и их пары, двойная спираль, широкое определение гена, некодирующие белок продукты РНК и различие генотипа и фенотипа подтверждаются источниками. Урок обоснованно отвергает упрощение «один ген — один признак» и учитывает влияние среды; конкретных ошибок не найдено.

**Sources / Источники:** [MedlinePlus Genetics, “What is DNA?” / MedlinePlus Genetics, «Что такое ДНК?»](https://medlineplus.gov/genetics/understanding/basics/dna/), [MedlinePlus Genetics, “What is a gene?” / MedlinePlus Genetics, «Что такое ген?»](https://medlineplus.gov/genetics/understanding/basics/gene/), [NHGRI, “Genotype” / NHGRI, «Генотип»](https://www.genome.gov/genetics-glossary/genotype), [NHGRI, “Phenotype” / NHGRI, «Фенотип»](https://www.genome.gov/genetics-glossary/Phenotype), [NHGRI, “Gene” / NHGRI, «Ген»](https://www.genome.gov/genetics-glossary/Gene).

### `ecosystem_energy_flow.md`

**Finding (EN):** The energy-transfer explanation, variable transfer fractions, warning that 10% is not universal, and both calculations are correct. **Concrete correction needed:** the opening sentence generalizes sunlight capture to primary producers as a whole. Some chemoautotrophic ecosystems obtain energy from inorganic molecules; specify that plants/algae are photosynthetic producers and mention chemosynthetic exceptions.  
**Результат (RU):** Объяснение передачи энергии, изменчивость доли переноса, оговорка о том, что 10% — не универсальное правило, и оба расчёта корректны. **Нужна конкретная правка:** первое предложение обобщает получение солнечной энергии на всех продуцентов. Некоторые хемоавтотрофные экосистемы получают энергию из неорганических веществ; уточните, что растения и водоросли — фотосинтезирующие продуценты, и упомяните хемосинтетические исключения.

**Sources / Источники:** [OpenStax Biology 2e §46.2, “Energy Flow through Ecosystems” / §46.2 «Поток энергии в экосистемах»](https://openstax.org/books/biology-2e/pages/46-2-energy-flow-through-ecosystems); add / добавить [§46.3, “Biogeochemical Cycles” / §46.3 «Биогеохимические циклы»](https://openstax.org/books/biology-2e/pages/46-3-biogeochemical-cycles), which states that energy can enter as sunlight or, for chemoautotrophs, inorganic molecules / где сказано, что энергия поступает как от солнечного света, так и, у хемоавтотрофов, из неорганических молекул.

### `eukaryotic_cell_organelles.md`

**Finding (EN):** Nucleus/ER/Golgi/membrane roles and the illustrated secretory-protein route are consistent with the sources. The lesson explicitly says that this route does not apply to every protein and that its 3D cell is not to scale; those are important and appropriate limits. No concrete factual error found.  
**Результат (RU):** Роли ядра, ЭПС, аппарата Гольджи и мембраны, а также показанный путь секретируемого белка согласуются с источниками. В уроке прямо сказано, что этот путь подходит не каждому белку, а 3D-клетка не выполнена в масштабе; это важные и уместные ограничения. Конкретных фактических ошибок не найдено.

**Sources / Источники:** [OpenStax Biology 2e §4.3, “Eukaryotic Cells” / §4.3 «Эукариотические клетки»](https://openstax.org/books/biology-2e/pages/4-3-eukaryotic-cells), [§4.4, “The Endomembrane System and Proteins” / §4.4 «Эндомембранная система и белки»](https://openstax.org/books/biology-2e/pages/4-4-the-endomembrane-system-and-proteins), [§5.1, “Components and Structure” / §5.1 «Компоненты и строение мембраны»](https://openstax.org/books/biology-2e/pages/5-1-components-and-structure).

### `food_webs_and_matter_cycles.md`

**Finding (EN):** The arrow direction, distinction between a chain and a web, detrital pathways, decomposers, and the contrast between cycling matter and one-way energy flow match OpenStax. The fictional-pond and non-predictive-model warnings are appropriate. No concrete factual error found.  
**Результат (RU):** Направление стрелок, различие цепи и сети, детритные пути, разлагатели и отличие круговорота вещества от однонаправленного потока энергии соответствуют OpenStax. Оговорки о вымышленной прудовой сети и том, что модель не является прогнозной, уместны. Конкретных фактических ошибок не найдено.

**Sources / Источники:** [OpenStax Biology 2e §46.1, “Ecology of Ecosystems” / §46.1 «Экология экосистем»](https://openstax.org/books/biology-2e/pages/46-1-ecology-of-ecosystems), [§46.3, “Biogeochemical Cycles” / §46.3 «Биогеохимические циклы»](https://openstax.org/books/biology-2e/pages/46-3-biogeochemical-cycles).

### `gene_expression_and_regulation.md`

**Finding (EN):** The strand orientation, complementary transcript, and stop-codon interpretation are correct. The current citations support transcription/translation and regulation generally, but do not directly substantiate the exact `AUG = Met`, `CCU = Pro`, and `UGA = Stop` mapping; add the NCBI standard genetic-code table. The lesson already limits the example to a simplified standard-code case.  
**Результат (RU):** Направление цепи, комплементарная РНК и трактовка стоп-кодона указаны верно. Текущие ссылки в целом подтверждают транскрипцию, трансляцию и регуляцию, но напрямую не обосновывают точные соответствия `AUG = Met`, `CCU = Pro` и `UGA = Stop`; добавьте таблицу стандартного генетического кода NCBI. В уроке уже есть оговорка, что это упрощённый пример со стандартным кодом.

**Sources / Источники:** [MedlinePlus Genetics, “How do genes direct the production of proteins?” / MedlinePlus Genetics, «Как гены направляют синтез белков?»](https://medlineplus.gov/genetics/understanding/howgeneswork/makingprotein/), [NHGRI, “Gene Expression” / NHGRI, «Экспрессия генов»](https://www.genome.gov/genetics-glossary/Gene-Expression), [NHGRI, “Gene Regulation” / NHGRI, «Регуляция генов»](https://www.genome.gov/genetics-glossary/Gene-Regulation), [NCBI, “The Genetic Codes: Standard Code” / NCBI, «Генетические коды: стандартный код»](https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?chapter=tgencodes).

### `mendelian_inheritance.md`

**Finding (EN):** For the stated assumptions, `Aa × Aa` gives 1:2:1 genotype expectations and 25% `aa`; the 3:1 phenotype ratio is correctly conditioned on complete dominance. The lesson also flags linkage, other inheritance patterns, environment, and small-sample variation. No concrete factual or arithmetic error found.  
**Результат (RU):** При заявленных допущениях скрещивание `Aa × Aa` даёт ожидаемое соотношение генотипов 1:2:1 и вероятность `aa` 25%; соотношение фенотипов 3:1 правильно ограничено случаем полного доминирования. Урок также учитывает сцепление генов, другие типы наследования, влияние среды и отклонения при малой выборке. Фактических или арифметических ошибок не найдено.

**Source / Источник:** [OpenStax Biology 2e §12.3, “Laws of Inheritance” / §12.3 «Законы наследования»](https://openstax.org/books/biology-2e/pages/12-3-laws-of-inheritance).

### `natural_selection_and_population_change.md`

**Finding (EN):** Heritable variation, differential reproductive success, population-level change across generations, and the absence of goal-directed mutation are all supported. The deterministic one-trait simulator is explicitly described as illustrative rather than predictive. No concrete factual error found.  
**Результат (RU):** Наследуемая изменчивость, различия в репродуктивном успехе, изменение популяции между поколениями и отсутствие направленных к цели мутаций подтверждаются источниками. Детерминированный симулятор одного признака прямо обозначен как иллюстративная, а не прогнозная модель. Конкретных фактических ошибок не найдено.

**Sources / Источники:** [OpenStax Biology 2e §18.1, “Understanding Evolution” / §18.1 «Понимание эволюции»](https://openstax.org/books/biology-2e/pages/18-1-understanding-evolution), [§19.3, “Adaptive Evolution” / §19.3 «Адаптивная эволюция»](https://openstax.org/books/biology-2e/pages/19-3-adaptive-evolution).

### `passive_transport_osmosis.md`

**Finding (EN):** Diffusion, facilitated diffusion, osmosis, tonicity, and the red-cell answer are correct under the stated semipermeable-membrane/nonpenetrating-solute assumption. **Wording to refine:** “without a continuing energy source, net flow decreases” can imply diffusion itself needs an energy supply. The net flux declines as the gradient approaches equilibrium; say that external processes must maintain the gradient for sustained net flux.  
**Результат (RU):** Диффузия, облегчённая диффузия, осмос, тоничность и ответ для эритроцита корректны при заявленном условии о полупроницаемой мембране и непроникающем растворённом веществе. **Формулировку лучше уточнить:** слова «без постоянного источника энергии чистый поток уменьшается» могут создать впечатление, будто самой диффузии нужна энергия. Чистый поток снижается по мере приближения градиента к равновесию; для длительного сохранения потока внешние процессы должны поддерживать градиент.

**Sources / Источники:** [OpenStax Biology 2e §5.2, “Passive Transport” / §5.2 «Пассивный транспорт»](https://openstax.org/books/biology-2e/pages/5-2-passive-transport), [§41.1, “Osmoregulation and Osmotic Balance” / §41.1 «Осморегуляция и осмотический баланс»](https://openstax.org/books/biology-2e/pages/41-1-osmoregulation-and-osmotic-balance).

### `photosynthesis_energy_and_carbon.md`

**Finding (EN):** Chloroplast location, light-dependent production of ATP/NADPH, oxygen release from water splitting, Calvin-cycle carbon fixation, and the G3P description are supported. The greenhouse example is explicitly conditional on the simplified model, and the limits correctly reject a dark-only interpretation of the Calvin cycle. No concrete factual error found.  
**Результат (RU):** Локализация фотосинтеза в хлоропластах, образование ATP/NADPH в светозависимых реакциях, выделение кислорода при расщеплении воды, фиксация углерода циклом Кальвина и описание G3P подтверждаются источниками. Пример с теплицей явно привязан к упрощённой модели, а ограничения правильно исключают трактовку цикла Кальвина как процесса, идущего только в темноте. Конкретных фактических ошибок не найдено.

**Sources / Источники:** [OpenStax Biology 2e §8.1, “Overview of Photosynthesis” / §8.1 «Обзор фотосинтеза»](https://openstax.org/books/biology-2e/pages/8-1-overview-of-photosynthesis), [§8.2, “The Light-Dependent Reactions of Photosynthesis” / §8.2 «Светозависимые реакции фотосинтеза»](https://openstax.org/books/biology-2e/pages/8-2-the-light-dependent-reactions-of-photosynthesis), [§8.3, “Using Light Energy to Make Organic Molecules” / §8.3 «Использование энергии света для синтеза органических молекул»](https://openstax.org/books/biology-2e/pages/8-3-using-light-energy-to-make-organic-molecules).

### `scientific_method_and_experiments.md`

**Finding (EN):** The distinctions among observation, hypothesis, prediction, variables, controls, and cautious interpretation are consistent with the cited source. The recommendation for independent biological replicates and the exercise’s three-plant minimum are not directly supported by §1.1; the lesson itself correctly warns that three plants do not guarantee statistical power. Add an experimental-design source for replication. No contradiction found.  
**Результат (RU):** Различия между наблюдением, гипотезой, предсказанием, переменными, контролем и осторожной интерпретацией согласуются с указанным источником. Рекомендация использовать независимые биологические повторности и минимум из трёх растений в упражнении напрямую не подтверждаются §1.1; сам урок правильно предупреждает, что три растения не гарантируют достаточную статистическую мощность. Добавьте источник по планированию экспериментов и повторностям. Противоречий не найдено.

**Sources / Источники:** [OpenStax Biology 2e §1.1, “The Science of Biology” / §1.1 «Наука биологии»](https://openstax.org/books/biology-2e/pages/1-1-the-science-of-biology); suggested direct support for independent experimental units / рекомендуемый прямой источник по независимым экспериментальным единицам: [Cornell Statistical Consulting Unit, “Diagnosing and Avoiding Pseudoreplication” / Консультационная группа Корнеллского университета по статистике, «Как выявлять и избегать псевдоповторностей»](https://cscu.cornell.edu/wp-content/uploads/pseudo.pdf).

## Cross-cutting notes / Общие замечания

**Finding (EN):** The lessons distinguish simplified models from real systems unusually clearly and generally avoid medical or species-specific extrapolation. The `source_checked` metadata predates this audit; update it only after applying and reviewing corrections/source additions. OpenStax pages reviewed display CC BY-NC-SA terms and state that ingestion into language-model/generative-AI offerings requires prior written permission; this audit does not determine whether the original summaries are derivative works. Recheck permissions before putting OpenStax text into RAG or commercially distributing material that incorporates its content.  
**Результат (RU):** Уроки достаточно чётко отделяют упрощённые модели от реальных систем и в целом не делают медицинских или видоспецифичных выводов без оснований. Метаданные `source_checked` датированы раньше этой проверки; обновлять их следует после внесения и повторной проверки правок и новых ссылок. На проверенных страницах OpenStax указана лицензия CC BY-NC-SA и требование предварительного письменного разрешения для загрузки материалов в языковые модели или generative-AI-сервисы; этот аудит не определяет, являются ли исходные конспекты производными материалами. Перед добавлением текста OpenStax в RAG или коммерческим распространением материалов с его содержимым повторно проверьте разрешения.

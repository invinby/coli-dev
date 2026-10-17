import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LESSON_PATH = ROOT / "02_Areas" / "Programming" / "lessons" / "computational_thinking.md"
PRACTICE_MODEL_PATH = ROOT / "macOS" / "ColiDev" / "App" / "AlgorithmicThinkingPractice.swift"
LOCALIZATION_PATH = ROOT / "macOS" / "ColiDev" / "App" / "L10n.swift"


class ComputationalThinkingLessonTests(unittest.TestCase):
    def test_bilingual_average_examples_cover_typical_boundary_and_invalid_inputs(self):
        lesson = LESSON_PATH.read_text(encoding="utf-8")
        sources = [
            source
            for source in re.findall(r"```python\s*\n(.*?)\n```", lesson, re.DOTALL)
            if re.search(r"(?m)^def mean\(", source)
        ]

        self.assertEqual(
            len(sources),
            2,
            "Both language sections must provide the runnable average example.",
        )

        for source in sources:
            namespace = {}
            exec(compile(source, str(LESSON_PATH), "exec"), namespace)
            mean = namespace["mean"]
            self.assertEqual(mean([2, 4, 6]), 4)
            self.assertEqual(mean([7]), 7)
            self.assertEqual(mean([-2, 2]), 0)
            with self.assertRaises(ValueError):
                mean([])

    def test_bilingual_lesson_teaches_distinct_decomposition_patterns(self):
        lesson = LESSON_PATH.read_text(encoding="utf-8")
        russian = re.search(r"## Русский\n(.*?)(?=\n## English\n)", lesson, re.DOTALL).group(1)
        english = re.search(r"## English\n(.*?)(?=\n## Sources\n)", lesson, re.DOTALL).group(1)

        for section, heading, examples in (
            (russian, "### Декомпозиция: разные задачи — разные шаги", ("жарких дней", "масштабировать рецепт")),
            (english, "### Decomposition: different tasks need different steps", ("hot days", "scale a recipe")),
        ):
            self.assertIn(heading, section)
            for example in examples:
                self.assertIn(example, section.lower())

    def test_bilingual_lesson_teaches_partitions_and_threshold_neighbors(self):
        lesson = LESSON_PATH.read_text(encoding="utf-8")
        russian = re.search(r"## Русский\n(.*?)(?=\n## English\n)", lesson, re.DOTALL).group(1)
        english = re.search(r"## English\n(.*?)(?=\n## Sources\n)", lesson, re.DOTALL).group(1)

        for section, heading, values in (
            (russian, "### Классы входов и значения у границы", ("64", "65", "66", "-1", "121")),
            (english, "### Input partitions and values around a boundary", ("64", "65", "66", "-1", "121")),
        ):
            self.assertIn(heading, section)
            for value in values:
                self.assertRegex(section, rf"(?<!\d){re.escape(value)}(?!\d)")

        self.assertIn("ISTQB", lesson)
        self.assertIn("CS2023", lesson)

    def test_practice_model_keys_have_bilingual_localizations(self):
        practice_model = PRACTICE_MODEL_PATH.read_text(encoding="utf-8")
        localization = LOCALIZATION_PATH.read_text(encoding="utf-8")
        used_keys = set(re.findall(r'"(lab\.[A-Za-z0-9_.]+)"', practice_model))
        localized_keys = set(re.findall(r'"(lab\.[A-Za-z0-9_.]+)"\s*:', localization))

        self.assertTrue(used_keys, "The interactive practice must expose localized content keys.")
        self.assertFalse(
            used_keys - localized_keys,
            f"Practice keys without RU/EN copy: {sorted(used_keys - localized_keys)}",
        )


if __name__ == "__main__":
    unittest.main()

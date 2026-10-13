import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LESSON_PATH = ROOT / "02_Areas" / "Programming" / "lessons" / "computational_thinking.md"


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


if __name__ == "__main__":
    unittest.main()

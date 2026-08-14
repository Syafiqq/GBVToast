import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[2] / "Scripts/generate_snapshot_comparison.py"
SPEC = importlib.util.spec_from_file_location("snapshot_report", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class SnapshotComparisonTests(unittest.TestCase):
    def test_discovers_complete_renderer_matrix(self):
        pairs = MODULE.discover_pairs()
        self.assertEqual(len(pairs), 23)
        self.assertEqual(sum(pair.geniebook is not None for pair in pairs), 18)
        self.assertEqual(sum(pair.swiftui is not None for pair in pairs), 23)
        self.assertTrue(any(pair.geniebook is None for pair in pairs))

    def test_unmatched_snapshot_keeps_an_empty_opposite_column(self):
        with tempfile.TemporaryDirectory() as directory:
            snapshots = Path(directory)
            source = MODULE.SNAPSHOT_DIR / "testUIKitParityMatrix.stress-large-icon.png"
            source = MODULE.SNAPSHOT_DIR / "testSwiftUIParityMatrixFullPage.stress-large-icon.png"
            (snapshots / "testSwiftUIParityMatrix.swiftui-only.png").write_bytes(source.read_bytes())
            matrix_path = snapshots / "matrix.json"
            matrix_path.write_text(json.dumps({"groups": [{
                "name": "Test matrix",
                "swiftuiPrefix": "testSwiftUIParityMatrix",
                "defaultDevice": "Test Phone — 100×200 pt",
                "cases": ["both-missing", "swiftui-only"]
            }]}))

            golden = snapshots / "golden"
            golden.mkdir()
            (golden / "manifest.json").write_text(json.dumps({"cases": {
                name: {"status": "unsupported", "reason": "test"}
                for name in ["both-missing", "swiftui-only"]
            }}))
            matrix = MODULE.discover_pairs(snapshots, matrix_path, golden)

            self.assertEqual(
                [pair.name for pair in matrix],
                ["both-missing", "swiftui-only"],
            )
            self.assertIsNone(matrix[0].swiftui)
            self.assertIsNotNone(matrix[1].swiftui)
            report = MODULE.build_html(matrix)
            self.assertIn("Not available in Geniebook production", report)
            self.assertIn("Not available in GBVToast SwiftUI", report)

    def test_generated_report_is_self_contained_and_side_by_side(self):
        report = MODULE.build_html(MODULE.discover_pairs()[:1])
        self.assertIn("data:image/png;base64,", report)
        self.assertIn('class="two-up"', report)
        self.assertIn("Geniebook production", report)
        self.assertIn("GBVToast SwiftUI", report)
        self.assertNotIn('type="range"', report)
        self.assertNotIn("function slide", report)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "bin"))

import status as omaduo_status  # noqa: E402
import hypr_block  # noqa: E402


class HardwareGate(unittest.TestCase):
    def test_board_match(self) -> None:
        self.assertTrue(omaduo_status.is_duo("UX8406CA", "something"))

    def test_product_match(self) -> None:
        self.assertTrue(omaduo_status.is_duo("", "ASUS Zenbook Duo UX8406CA_UX8406CA"))

    def test_rejects_other(self) -> None:
        self.assertFalse(omaduo_status.is_duo("UX3405MA", "Zenbook"))


class HyprBlock(unittest.TestCase):
    def test_apply_appends(self) -> None:
        out = hypr_block.apply_block("-- other\n", "o.bind(\"SUPER + R\", \"x\", \"y\")")
        self.assertIn(hypr_block.BEGIN, out)
        self.assertIn("SUPER + R", out)
        self.assertIn(hypr_block.END, out)

    def test_apply_replaces(self) -> None:
        first = hypr_block.apply_block("", "one")
        second = hypr_block.apply_block(first, "two")
        self.assertEqual(second.count(hypr_block.BEGIN), 1)
        self.assertIn("two", second)
        self.assertNotIn("one", second)

    def test_remove(self) -> None:
        text = hypr_block.apply_block("keep\n", "drop")
        out = hypr_block.remove_block(text)
        self.assertEqual(out.strip(), "keep")
        self.assertNotIn(hypr_block.BEGIN, out)

    def test_remove_missing_is_noop(self) -> None:
        self.assertEqual(hypr_block.remove_block("keep\n"), "keep\n")


if __name__ == "__main__":
    unittest.main()

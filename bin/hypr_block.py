#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

BEGIN = "-- omaduo:begin"
END = "-- omaduo:end"


def apply_block(text: str, body: str) -> str:
    block = f"{BEGIN}\n{body.rstrip()}\n{END}\n"
    start = text.find(BEGIN)
    if start == -1:
        if text and not text.endswith("\n"):
            text += "\n"
        return text + "\n" + block
    end = text.find(END, start)
    if end == -1:
        raise ValueError("omaduo begin marker without end")
    end = end + len(END)
    if end < len(text) and text[end] == "\n":
        end += 1
    return text[:start] + block + text[end:]


def remove_block(text: str) -> str:
    start = text.find(BEGIN)
    if start == -1:
        return text
    end = text.find(END, start)
    if end == -1:
        raise ValueError("omaduo begin marker without end")
    end = end + len(END)
    if end < len(text) and text[end] == "\n":
        end += 1
    before = text[:start].rstrip("\n")
    after = text[end:]
    if before and after:
        return before + "\n\n" + after.lstrip("\n")
    return before + after


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("apply", "remove", "has"))
    parser.add_argument("file", type=Path)
    parser.add_argument("--body-file", type=Path)
    args = parser.parse_args()
    text = args.file.read_text(encoding="utf-8") if args.file.is_file() else ""
    if args.action == "has":
        print("yes" if BEGIN in text else "no")
        return 0
    if args.action == "apply":
        if args.body_file is None:
            raise SystemExit("--body-file is required for apply")
        body = args.body_file.read_text(encoding="utf-8")
        out = apply_block(text, body)
    else:
        out = remove_block(text)
    args.file.parent.mkdir(parents=True, exist_ok=True)
    args.file.write_text(out, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

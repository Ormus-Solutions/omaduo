#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

DMI_BOARD = Path("/sys/class/dmi/id/board_name")
DMI_PRODUCT = Path("/sys/class/dmi/id/product_name")
USB_ROOT = Path("/sys/bus/usb/devices")
ROTATE_FLAG = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "omarchy/toggles/duo-rotate"
ROTATE_DIR = ROTATE_FLAG.with_name("duo-rotate.dir")
TOUCHPAD_OFF = (
    Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    / "omarchy/toggles/hypr/duo-touchpad-disabled.lua"
)
ACTIVATED = (
    Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    / "omarchy/omaduo-activated"
)
USB_VENDOR = "0b05"
USB_PRODUCT = "1bf2"


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace").strip()
    except OSError:
        return ""


def is_duo(board: str, product: str) -> bool:
    blob = f"{board} {product}"
    return "UX8406CA" in blob


def keyboard_attached(usb_root: Path = USB_ROOT) -> bool:
    if not usb_root.is_dir():
        return False
    for entry in usb_root.iterdir():
        vendor = entry / "idVendor"
        product = entry / "idProduct"
        if not vendor.is_file() or not product.is_file():
            continue
        if read_text(vendor) == USB_VENDOR and read_text(product) == USB_PRODUCT:
            return True
    return False


def portrait_transform() -> int:
    if not ROTATE_FLAG.is_file():
        return 0
    raw = read_text(ROTATE_DIR)
    if raw in {"1", "3"}:
        return int(raw)
    return 1


def edp2_disabled() -> bool | None:
    try:
        raw = subprocess.check_output(["hyprctl", "monitors", "-j"], text=True, timeout=2)
        monitors = json.loads(raw)
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        return None
    if not isinstance(monitors, list):
        return None
    for mon in monitors:
        if str(mon.get("name") or "") == "eDP-2":
            return bool(mon.get("disabled"))
    return None


def collect() -> dict[str, object]:
    board = os.environ.get("OMADUO_DMI_BOARD", read_text(DMI_BOARD))
    product = os.environ.get("OMADUO_DMI_PRODUCT", read_text(DMI_PRODUCT))
    hardware = is_duo(board, product)
    attached = keyboard_attached()
    transform = portrait_transform()
    pad_disabled = edp2_disabled()
    return {
        "ok": True,
        "hardware": hardware,
        "dmi": board or product,
        "keyboardOn": attached,
        "portrait": transform in {1, 3},
        "portraitTransform": transform,
        "trackpadOn": not TOUCHPAD_OFF.is_file(),
        "screenpadOn": (not attached) and pad_disabled is False,
        "activated": ACTIVATED.is_file(),
    }


def main() -> int:
    json.dump(collect(), sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

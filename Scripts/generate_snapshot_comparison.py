#!/usr/bin/env python3
"""Build a Geniebook golden / canonical GBVToast SwiftUI comparison report."""

from __future__ import annotations

import argparse
import base64
import html
import json
import struct
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT_DIR = (
    ROOT
    / "Tests/GBVToastTests/Snapshots/__Snapshots__/ToastSnapshotTests"
)
DEFAULT_OUTPUT = ROOT / ".build/reports/toast-snapshot-comparison.html"
DEFAULT_MATRIX = ROOT / "Tests/GBVToastTests/Fixtures/toast_snapshot_matrix.json"
DEFAULT_GOLDEN = ROOT / "golden-images/geniebook-toast-goldens"
DEVICE_TYPES = (
    "com.apple.CoreSimulator.SimDeviceType.iPhone-17",
    "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
    "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro",
)


@dataclass(frozen=True)
class SnapshotPair:
    group: str
    name: str
    device: str
    geniebook: Path | None
    swiftui: Path | None
    geniebook_status: str
    geniebook_reason: str | None


@dataclass(frozen=True)
class FocusedSnapshot:
    name: str
    detail: str
    image: Path


CENTERED_CTA_SNAPSHOTS = (
    (
        "Image CTA",
        "Single-line asset action",
        "testImageCTAContractMatrix.inline-phone.png",
    ),
    (
        "Image CTA with long message",
        "Multiline message beside an asset action",
        "testImageCTAContractMatrix.responsive-long-message.png",
    ),
    (
        "Image CTA right to left",
        "Semantic trailing placement in a right-to-left environment",
        "testImageCTAContractMatrix.right-to-left.png",
    ),
    (
        "Text CTA with large icon",
        "Text action in a row with unequal content heights",
        "testCTAContractMatrix.stress-large-icon.png",
    ),
    (
        "Text CTA with long label",
        "Multiline text action centered against its message row",
        "testCTAContractMatrix.stress-long-cta.png",
    ),
)


def run(command: list[str], *, capture: bool = False) -> str:
    print("+", " ".join(command), flush=True)
    completed = subprocess.run(
        command,
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
    )
    return completed.stdout if capture else ""


def available_simulators() -> list[dict[str, object]]:
    payload = json.loads(run(["xcrun", "simctl", "list", "devices", "-j"], capture=True))
    return [
        device
        for runtime_devices in payload["devices"].values()
        for device in runtime_devices
        if device.get("isAvailable")
    ]


def resolve_device(requested: str | None) -> str:
    devices = available_simulators()
    if requested:
        matches = [device for device in devices if requested in (device["udid"], device["name"])]
        if len(matches) != 1:
            raise SystemExit(f"Expected one available simulator matching {requested!r}; found {len(matches)}")
        return str(matches[0]["udid"])

    booted = next((device for device in devices if device.get("state") == "Booted"), None)
    if booted:
        return str(booted["udid"])

    iphone = next((device for device in devices if str(device.get("name", "")).startswith("iPhone")), None)
    if not iphone:
        raise SystemExit("No available iPhone simulator was found")
    return str(iphone["udid"])


def run_snapshots(device: str) -> None:
    is_booted = any(
        simulator["udid"] == device and simulator.get("state") == "Booted"
        for simulator in available_simulators()
    )
    if not is_booted:
        run(["xcrun", "simctl", "boot", device])
    run(["xcrun", "simctl", "bootstatus", device, "-b"])
    derived_data = ROOT / ".build/snapshot-comparison-derived-data"
    run(
        [
            "xcodebuild",
            "test",
            "-workspace",
            ".swiftpm/xcode/package.xcworkspace",
            "-scheme",
            "GBVToast",
            "-destination",
            f"platform=iOS Simulator,id={device}",
            "-derivedDataPath",
            str(derived_data),
            "-only-testing:GBVToastTests/ToastSnapshotTests",
            "-parallel-testing-enabled",
            "NO",
            "-test-timeouts-enabled",
            "YES",
            "-maximum-test-execution-time-allowance",
            "120",
            "CODE_SIGNING_ALLOWED=NO",
        ]
    )


def discover_pairs(
    snapshot_dir: Path = SNAPSHOT_DIR,
    matrix_path: Path = DEFAULT_MATRIX,
    golden_dir: Path = DEFAULT_GOLDEN,
) -> list[SnapshotPair]:
    matrix = json.loads(matrix_path.read_text(encoding="utf-8"))
    golden_manifest_path = golden_dir / "manifest.json"
    golden_manifest = json.loads(golden_manifest_path.read_text(encoding="utf-8"))
    golden_cases = golden_manifest["cases"]
    matrix_keys = [name for group in matrix["groups"] for name in group["cases"]]
    missing_keys = sorted(set(matrix_keys) - set(golden_cases))
    extra_keys = sorted(set(golden_cases) - set(matrix_keys))
    if missing_keys or extra_keys:
        raise SystemExit(
            f"Golden manifest/matrix key mismatch; missing={missing_keys}, extra={extra_keys}"
        )
    pairs: list[SnapshotPair] = []
    for group in matrix["groups"]:
        swiftui_prefix = group["swiftuiPrefix"]
        for name in group["cases"]:
            golden_case = golden_cases[name]
            status = golden_case["status"]
            golden = golden_dir / golden_case["image"] if status == "captured" else None
            if golden is not None and not golden.exists():
                raise SystemExit(f"Missing captured Geniebook golden: {golden}")
            swiftui = snapshot_dir / f"{swiftui_prefix}.{name}.png"
            pairs.append(
                SnapshotPair(
                    group["name"],
                    name,
                    group.get("deviceOverrides", {}).get(name, group["defaultDevice"]),
                    golden,
                    swiftui if swiftui.exists() else None,
                    status,
                    golden_case.get("reason"),
                )
            )
    if not pairs:
        raise SystemExit(f"No UIKit or SwiftUI snapshots found in {snapshot_dir}")
    return pairs


def discover_centered_cta_snapshots(
    snapshot_dir: Path = SNAPSHOT_DIR,
) -> list[FocusedSnapshot]:
    snapshots = [
        FocusedSnapshot(name, detail, snapshot_dir / filename)
        for name, detail, filename in CENTERED_CTA_SNAPSHOTS
    ]
    missing = [
        str(snapshot.image)
        for snapshot in snapshots
        if not snapshot.image.exists()
    ]
    if missing:
        raise SystemExit(f"Missing centered CTA snapshots: {missing}")
    return snapshots


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as image:
        header = image.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"Not a supported PNG: {path}")
    return struct.unpack(">II", header[16:24])


def data_uri(path: Path) -> str:
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:image/png;base64,{encoded}"


def dimensions(path: Path | None) -> str:
    if path is None:
        return "—"
    width, height = png_size(path)
    return f"{width}×{height}"


def renderer_panel(renderer: str, path: Path | None, title: str, reason: str | None = None) -> str:
    if path is None:
        detail = f"<small>{html.escape(reason)}</small>" if reason else ""
        content = f'<div class="empty">Not available in {renderer}{detail}</div>'
    else:
        content = f'<img src="{data_uri(path)}" alt="{renderer} {title}">'
    return f"<figure><figcaption>{renderer}</figcaption>{content}</figure>"


def card(pair: SnapshotPair) -> str:
    title = html.escape(pair.name.replace("-", " ").title())
    return f"""
      <article class="card">
        <header><div><h2>{title}</h2><span class="device">{html.escape(pair.device)}</span></div><code>{dimensions(pair.geniebook)} / {dimensions(pair.swiftui)}</code></header>
        <div class="two-up">
          {renderer_panel("Geniebook production", pair.geniebook, title, pair.geniebook_reason)}
          {renderer_panel("GBVToast SwiftUI", pair.swiftui, title)}
        </div>
      </article>"""


def focused_card(snapshot: FocusedSnapshot) -> str:
    title = html.escape(snapshot.name)
    return f"""
      <article class="card focused-card">
        <header><div><h2>{title}</h2><span class="device">{html.escape(snapshot.detail)}</span></div>
        <code>{dimensions(snapshot.image)}</code></header>
        <figure><img src="{data_uri(snapshot.image)}" alt="GBVToast SwiftUI {title}"></figure>
      </article>"""


def build_html(
    pairs: list[SnapshotPair],
    centered_ctas: list[FocusedSnapshot] | None = None,
) -> str:
    focused = ""
    if centered_ctas:
        focused = (
            '<section class="focused"><h1>Centered inline CTA</h1>'
            '<p>Vertically centered against the complete inline message row, '
            'the CTA interaction frame remains at semantic trailing.</p>'
            '<div class="focused-grid">'
            + "".join(focused_card(snapshot) for snapshot in centered_ctas)
            + "</div></section>"
        )
    groups: list[str] = []
    for group in dict.fromkeys(pair.group for pair in pairs):
        group_pairs = [(index, pair) for index, pair in enumerate(pairs) if pair.group == group]
        groups.append(
            f'<section><h1>{html.escape(group)}</h1><div class="grid">'
            + "".join(card(pair) for _, pair in group_pairs)
            + "</div></section>"
        )
    return """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Geniebook / GBVToast SwiftUI comparison</title>
<style>
:root{color-scheme:dark;font:15px system-ui;background:#101217;color:#f6f7fb}body{margin:0;padding:28px}
main{max-width:1500px;margin:auto}h1{margin:38px 0 16px}h2{font-size:16px;margin:0;text-transform:none}
.grid{display:grid;grid-template-columns:1fr;gap:22px}.card{background:#1a1e27;border:1px solid #303746;border-radius:14px;padding:16px;box-shadow:0 8px 28px #0005}
header{display:flex;align-items:baseline;justify-content:space-between;gap:12px;margin-bottom:12px}.device{display:block;color:#98a2b8;font-size:12px;margin-top:4px}code{color:#98a2b8;font-size:12px}.two-up{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.two-up figure,.focused-card figure{margin:0;background:repeating-conic-gradient(#181d26 0 25%,#141922 0 50%) 0/20px 20px;border:1px solid #303746;border-radius:9px;padding:10px}.two-up figcaption{font-size:12px;font-weight:700;color:#cbd3e2;margin-bottom:8px}.two-up img,.focused-card img{display:block;width:100%;height:auto}.focused>p{color:#cbd3e2;max-width:70em}.focused-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:22px}.empty{display:grid;place-items:center;align-content:center;gap:8px;min-height:140px;color:#7f899d;border:1px dashed #465064;border-radius:7px;background:#11151ccc;text-align:center;padding:16px}.empty small{max-width:30em}@media(max-width:800px){body{padding:14px}.two-up,.focused-grid{grid-template-columns:1fr}}
</style></head><body><main><h1>Toast renderer comparison</h1><p>Left: imported Geniebook production golden. Right: canonical GBVToast SwiftUI. Dimensions follow the same order.</p>
""" + focused + "".join(groups) + """</main></body></html>"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", help="Simulator UDID or exact name; defaults to a booted iPhone")
    parser.add_argument("--skip-tests", action="store_true", help="Generate HTML from existing PNGs")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="HTML output path")
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX, help="Ground-truth matrix JSON")
    parser.add_argument("--golden-dir", type=Path, default=DEFAULT_GOLDEN, help="Geniebook golden export directory")
    return parser.parse_args()


def main() -> int:
    arguments = parse_args()
    if not arguments.skip_tests:
        run_snapshots(resolve_device(arguments.device))
    pairs = discover_pairs(matrix_path=arguments.matrix, golden_dir=arguments.golden_dir)
    centered_ctas = discover_centered_cta_snapshots()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(build_html(pairs, centered_ctas), encoding="utf-8")
    print(
        f"Wrote {len(pairs)} comparisons and {len(centered_ctas)} centered CTA snapshots "
        f"to {arguments.output}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

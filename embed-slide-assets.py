#!/usr/bin/env python3
"""Inline local image/diagram references in Marp HTML as base64 data URIs."""

from __future__ import annotations

import argparse
import base64
import mimetypes
import re
import sys
from pathlib import Path

# Match url(...), src="...", href="..." local asset paths (not http/data)
URL_RE = re.compile(
    r"""(?P<prefix>url\(\s*(?:&quot;|&apos;|"|')?)"""
    r"""(?P<path>(?:\./)?(?:images|diagrams)/[^"'\)\s&]+)"""
    r"""(?P<suffix>(?:&quot;|&apos;|"|')?\s*\))""",
    re.IGNORECASE,
)
ATTR_RE = re.compile(
    r"""(?P<prefix>\b(?:src|href)=(?P<q>["']))"""
    r"""(?P<path>(?:\./)?(?:images|diagrams)/[^"']+)"""
    r"""(?P=q)""",
    re.IGNORECASE,
)


def mime_for(path: Path) -> str:
    mime, _ = mimetypes.guess_type(str(path))
    if mime:
        return mime
    suffix = path.suffix.lower()
    return {
        ".svg": "image/svg+xml",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".webp": "image/webp",
        ".bmp": "image/bmp",
    }.get(suffix, "application/octet-stream")


def to_data_uri(path: Path, cache: dict[str, str]) -> str | None:
    key = str(path.resolve())
    if key in cache:
        return cache[key]
    if not path.is_file():
        return None
    data = path.read_bytes()
    uri = f"data:{mime_for(path)};base64,{base64.b64encode(data).decode('ascii')}"
    cache[key] = uri
    return uri


def resolve_asset(raw_path: str, html_dir: Path, extra_roots: list[Path]) -> Path | None:
    cleaned = raw_path.replace("&quot;", "").replace("&apos;", "").strip()
    candidates = [html_dir / cleaned]
    for root in extra_roots:
        candidates.append(root / cleaned)
        # also try without leading ./
        candidates.append(root / cleaned.lstrip("./"))
        # marp may emit diagrams/... while files live under slides/diagrams
        if cleaned.startswith("diagrams/"):
            candidates.append(root / cleaned)
        if cleaned.startswith("images/"):
            candidates.append(root / cleaned)
        if cleaned.startswith("./images/"):
            candidates.append(root / cleaned[2:])
        if cleaned.startswith("./diagrams/"):
            candidates.append(root / cleaned[2:])
    for cand in candidates:
        if cand.is_file():
            return cand
    return None


def embed_html(html_path: Path, extra_roots: list[Path]) -> tuple[int, int]:
    text = html_path.read_text(encoding="utf-8", errors="ignore")
    html_dir = html_path.parent
    cache: dict[str, str] = {}
    missing: list[str] = []
    replaced = 0

    def replace_match(m: re.Match[str]) -> str:
        nonlocal replaced
        raw = m.group("path")
        asset = resolve_asset(raw, html_dir, extra_roots)
        if asset is None:
            missing.append(raw)
            return m.group(0)
        uri = to_data_uri(asset, cache)
        if uri is None:
            missing.append(raw)
            return m.group(0)
        replaced += 1
        return f"{m.group('prefix')}{uri}{m.group('suffix')}"

    def replace_attr(m: re.Match[str]) -> str:
        nonlocal replaced
        raw = m.group("path")
        q = m.group("q")
        asset = resolve_asset(raw, html_dir, extra_roots)
        if asset is None:
            missing.append(raw)
            return m.group(0)
        uri = to_data_uri(asset, cache)
        if uri is None:
            missing.append(raw)
            return m.group(0)
        replaced += 1
        return f"{m.group('prefix')}{uri}{q}"

    text = URL_RE.sub(replace_match, text)
    text = ATTR_RE.sub(replace_attr, text)

    html_path.write_text(text, encoding="utf-8")
    unique_missing = sorted(set(missing))
    return replaced, len(unique_missing)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("html_files", nargs="+", type=Path)
    parser.add_argument(
        "--asset-root",
        action="append",
        default=[],
        type=Path,
        help="Extra directories that contain images/ or diagrams/ (repeatable)",
    )
    args = parser.parse_args()

    total_replaced = 0
    total_missing = 0
    for html in args.html_files:
        if not html.is_file():
            print(f"[skip] not found: {html}", file=sys.stderr)
            continue
        replaced, missing = embed_html(html, args.asset_root)
        total_replaced += replaced
        total_missing += missing
        print(f"[embed] {html.name}: {replaced} assets inlined, {missing} missing")

    print(f"[done] {total_replaced} total inlined, {total_missing} missing path reports")
    return 0 if total_missing == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())

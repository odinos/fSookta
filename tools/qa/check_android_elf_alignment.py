#!/usr/bin/env python3
"""Check Android shared libraries for 16 KB ELF LOAD segment alignment."""

from __future__ import annotations

import argparse
import struct
import sys
import tempfile
import zipfile
from pathlib import Path


REQUIRED_ALIGNMENT = 0x4000
PT_LOAD = 1


def _iter_so_files(path: Path):
    if path.is_dir():
        yield from sorted(path.rglob("*.so"))
        return
    if path.suffix in {".apk", ".aab", ".aar", ".zip"}:
        with tempfile.TemporaryDirectory() as temp_dir:
            with zipfile.ZipFile(path) as zf:
                for name in zf.namelist():
                    if name.endswith(".so"):
                        zf.extract(name, temp_dir)
            yield from sorted(Path(temp_dir).rglob("*.so"))
        return
    if path.suffix == ".so":
        yield path


def _load_alignments(path: Path) -> list[int]:
    data = path.read_bytes()
    if data[:4] != b"\x7fELF":
        raise ValueError(f"{path} is not an ELF file")
    elf_class = data[4]
    endian = data[5]
    prefix = "<" if endian == 1 else ">"
    if elf_class == 1:
        header = struct.unpack_from(prefix + "HHIIIIIHHHHHH", data, 16)
        e_phoff = header[4]
        e_phentsize = header[8]
        e_phnum = header[9]
        alignments: list[int] = []
        for index in range(e_phnum):
            offset = e_phoff + index * e_phentsize
            ph = struct.unpack_from(prefix + "IIIIIIII", data, offset)
            if ph[0] == PT_LOAD:
                alignments.append(ph[7])
        return alignments
    if elf_class == 2:
        header = struct.unpack_from(prefix + "HHIQQQIHHHHHH", data, 16)
        e_phoff = header[4]
        e_phentsize = header[8]
        e_phnum = header[9]
        alignments = []
        for index in range(e_phnum):
            offset = e_phoff + index * e_phentsize
            ph = struct.unpack_from(prefix + "IIQQQQQQ", data, offset)
            if ph[0] == PT_LOAD:
                alignments.append(ph[7])
        return alignments
    raise ValueError(f"{path} has unsupported ELF class {elf_class}")


def _abi_from_path(path: Path) -> str:
    parts = path.parts
    for index, part in enumerate(parts):
        if part == "lib" and index + 1 < len(parts):
            return parts[index + 1]
        if part == "jni" and index + 1 < len(parts):
            return parts[index + 1]
    for abi in ("arm64-v8a", "armeabi-v7a", "x86_64", "x86"):
        if abi in parts:
            return abi
    return "unknown"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", help="APK/AAB/ZIP, .so, or directory")
    parser.add_argument(
        "--required",
        type=lambda value: int(value, 0),
        default=REQUIRED_ALIGNMENT,
        help="Required PT_LOAD p_align value. Defaults to 0x4000.",
    )
    args = parser.parse_args()

    rows = []
    for raw_path in args.paths:
        for so_path in _iter_so_files(Path(raw_path)):
            aligns = _load_alignments(so_path)
            minimum = min(aligns) if aligns else 0
            ok = all(value >= args.required for value in aligns)
            rows.append((_abi_from_path(so_path), so_path.name, aligns, ok, so_path))

    if not rows:
        print("No .so files found.")
        return 0

    failed = False
    for abi, name, aligns, ok, so_path in sorted(rows):
        status = "ALIGNED" if ok else "UNALIGNED"
        if not ok:
            failed = True
        align_text = ",".join(f"0x{value:x}" for value in aligns)
        print(f"{status:9} {abi:12} {name:36} PT_LOAD_ALIGN={align_text} PATH={so_path}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Apply non-fuzzy gettext translations to an Xcode XLIFF template."""

import ast
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def unquote(value: str) -> str:
    return ast.literal_eval(value.strip())


def translations(po_path: Path) -> dict[str, str]:
    entries = []
    entry: dict[str, object] = {"flags": set()}
    field: str | None = None

    def finish() -> None:
        nonlocal entry, field
        source = entry.get("msgid")
        target = entry.get("msgstr")
        if source and target and "fuzzy" not in entry["flags"]:
            entries.append((source, target))
        entry = {"flags": set()}
        field = None

    for line in po_path.read_text(encoding="utf-8").splitlines():
        if not line:
            finish()
        elif line.startswith("#,"):
            entry["flags"].update(flag.strip() for flag in line[2:].split(","))
        elif line.startswith(("msgctxt ", "msgid ", "msgstr ")):
            field, value = line.split(" ", 1)
            entry[field] = unquote(value)
        elif line.startswith('"') and field:
            entry[field] = entry.get(field, "") + unquote(line)
    finish()
    return dict(entries)


def main(po_file: str, xliff_file: str) -> None:
    translated = translations(Path(po_file))
    tree = ET.parse(xliff_file)
    root = tree.getroot()
    namespace = root.tag.partition("}")[0].lstrip("{")
    ET.register_namespace("", namespace)

    for unit in root.findall(".//{*}trans-unit"):
        source = unit.find("{*}source")
        if source is None:
            continue
        target_text = translated.get("".join(source.itertext()))
        if target_text is None:
            continue

        target = unit.find("{*}target")
        if target is None:
            target = ET.Element(f"{{{namespace}}}target")
            unit.insert(list(unit).index(source) + 1, target)
        target.text = target_text
        target.set("state", "translated")

    tree.write(xliff_file, encoding="UTF-8", xml_declaration=True)


if __name__ == "__main__":
    main(*sys.argv[1:])

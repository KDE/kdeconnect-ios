#!/usr/bin/env python3

"""Copy XLIFF translator notes that Translate Toolkit omits into a POT file."""

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def po_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def main(xliff_path: str, pot_path: str) -> None:
    root = ET.parse(xliff_path).getroot()
    notes = {}

    for unit in root.findall(".//{*}trans-unit"):
        source = unit.find("{*}source")
        note = unit.find("{*}note")
        if source is None or note is None:
            continue

        source_text = "".join(source.itertext())
        note_text = "".join(note.itertext()).strip()
        if note_text and note_text != "No comment provided by engineer.":
            notes.setdefault(source_text, set()).add(note_text)

    pot = Path(pot_path)
    contents = pot.read_text()
    for source, note_texts in notes.items():
        marker = f"msgid {po_string(source)}"
        comments = "".join(f"#. {note}\n" for note in sorted(note_texts))
        if marker in contents and comments not in contents:
            contents = contents.replace(marker, f"{comments}{marker}")
    pot.write_text(contents)


if __name__ == "__main__":
    main(*sys.argv[1:])

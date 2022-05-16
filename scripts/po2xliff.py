#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
#
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import argparse
import xml.etree.ElementTree as ET
from typing import Final, Optional

from babel.messages.catalog import Catalog, Message
from babel.messages.pofile import read_po

########################################
# Constants
########################################

TOOL_VERSION: Final[int] = "0.0.1"
"""
Increment as semantic versioning.
"""

BUILD_NUMBER: Final[str] = "1"
"""
Always increase by 1 independent of TOOL_VERSION
(i.e. do NOT reset for each new TOOL_VERSION).
"""

NO_COMMENT: Final[str] = "No comment provided by engineer."
XLIFF_TEMPLATE: Final[str] = """\
<?xml version="1.0" encoding="UTF-8"?>
<xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.2" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd">
</xliff>
"""
SPACE_IN_PATH: Final[str] = "__SpAcE__"

########################################
# PO to XLIFF
########################################


def po2xliff(catalog: Catalog, kde: bool = False) -> ET.ElementTree:
    ET.register_namespace("", "urn:oasis:names:tc:xliff:document:1.2")
    ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    root = ET.fromstring(XLIFF_TEMPLATE)

    file: Optional[ET.Element] = None
    body: ET.Element

    locale: str = catalog.locale_identifier
    message: Message
    # skip the first metadata one
    for message in catalog:
        # "KDE Connect/..." got parsed into (KDE, None) and (Connect/..., None)
        # https://github.com/python-babel/babel/issues/654
        if kde:
            original = message.locations[0][0].replace(SPACE_IN_PATH, " ") if message.locations else None
        else:
            original = " ".join([location[0] for location in message.locations])
        id = message.context
        source = message.id
        target = message.string
        note = message.auto_comments[0] if message.auto_comments else NO_COMMENT

        # must have source location
        if not original:
            continue
        if file is None or file.get("original") != original:
            file = ET.SubElement(root, "file", {
                "original": original,
                "source-language": "en",
                "target-language": locale,
                "datatype": "plaintext"
            })
            header = ET.SubElement(file, "header")
            ET.SubElement(header, "tool", {
                "tool-id": "org.kde.kdeconnect.po2xliff",
                "tool-name": "po2xliff",
                "tool-version": TOOL_VERSION,
                "build-num": BUILD_NUMBER
            })
            body = ET.SubElement(file, "body")
        trans_unit = ET.SubElement(body, "trans-unit", {
            "id": id,
            "xml:space": "preserve"
        })
        ET.SubElement(trans_unit, "source").text = source
        ET.SubElement(trans_unit, "target").text = target
        ET.SubElement(trans_unit, "note").text = note
    return ET.ElementTree(root)

########################################
# Main
########################################


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Convert GNU gettext po files to XLIFF files'
    )
    parser.add_argument("-i", "--input", required=True, help="Path to po")
    parser.add_argument("-o", "--output", required=True, help="Path to XLIFF")
    parser.add_argument("--kde", help="Workarounds for KDE specific workflow",
                        action="store_true")

    args = parser.parse_args()
    with open(args.input) as input:
        catalog = read_po(input)
        tree = po2xliff(catalog, args.kde)
        ET.indent(tree)
        tree.write(args.output, encoding="UTF-8", xml_declaration=True)

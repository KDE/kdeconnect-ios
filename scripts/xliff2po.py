#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
#
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

import argparse
import re
import xml.etree.ElementTree as ET
from typing import AnyStr, Final, Pattern

from babel import Locale
from babel.messages.catalog import Catalog
from babel.messages.pofile import write_po

########################################
# Constants
########################################

NS: Final[dict[str, str]] = {
    "xliff": "urn:oasis:names:tc:xliff:document:1.2"
}
NO_COMMENT: Final[str] = "No comment provided by engineer."
OBJC_FORMAT: Final[Pattern[AnyStr]] = re.compile(r"%(\d+\$)?@")

########################################
# XLIFF to POT
########################################


def xliff2po(xliff_path: str, pot: bool = True) -> Catalog:
    catalog = Catalog(
        project="KDE Connect iOS",
        copyright_holder="KDE Community & contributors",
        msgid_bugs_address="apple-feedback@kde.org",
        header_comment="""\
# Translations template for PROJECT.
# Copyright (C) 2014-YEAR ORGANIZATION\n
# This file is distributed under the same license as the PROJECT project.
#
# Apollo Zhu <public-apollonian@outlook.com>, 2022.
#"""
    )
    tree = ET.parse(xliff_path)
    for file in tree.getroot().findall("xliff:file", NS):
        reference = file.get("original")
        if not pot and not catalog.locale_identifier:
            target_language = file.get("target-language")
            if target_language:
                catalog.locale = Locale(target_language)
        for trans_unit in file.find("xliff:body", NS).findall("xliff:trans-unit", NS):
            msgctxt = trans_unit.get("id")
            msgid = trans_unit.find("xliff:source", NS).text
            msgstr = trans_unit.find("xliff:target", NS).text
            extracted_comments = trans_unit.find("xliff:note", NS).text
            no_comments = extracted_comments == NO_COMMENT
            objc_format = bool(re.search(OBJC_FORMAT, msgid))
            flags = ["objc-format"] if objc_format else ()

            catalog.add(
                auto_comments=() if no_comments else [extracted_comments],
                locations=[(reference, None)],
                flags=flags,
                context=msgctxt,
                id=msgid,
                string=None if pot else msgstr
            )
    return catalog

########################################
# Main
########################################


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Convert XLIFF files to GNU gettext po/pot files'
    )
    parser.add_argument("-P", "--pot", help="Output pot instead of po",
                        action="store_true")
    parser.add_argument("-i", "--input", required=True, help="Path to XLIFF")
    parser.add_argument("-o", "--output", required=True, help="Path to po/pot")

    args = parser.parse_args()
    with open(args.output, "wb") as f:
        write_po(f, xliff2po(args.input, args.pot))

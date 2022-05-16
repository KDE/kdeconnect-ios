#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
#
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

from typing import Final, Optional
import datetime
import xml.etree.ElementTree as ET

########################################
# Constants
########################################

NS: Final[dict[str, str]] = {
    "xliff" : "urn:oasis:names:tc:xliff:document:1.2"
}
NO_COMMENT: Final[str] = "No comment provided by engineer."

########################################
# XLIFF to POT
########################################

def make_pot_header(date: Optional[datetime.datetime] = None):
    if date is None:
        date = datetime.datetime.now(datetime.timezone.utc)
    return rf"""# KDE Connect iOS
# This file is distributed under the same license as the KDE Connect projects.
#
# Dear potential translators:
# Thank you for your interest in KDE Connect!
# We do not actually handle our own translations.
# All translations for all KDE apps are
# handled by the [localization team](https://l10n.kde.org).
# We really appreciate your translations,
# but make sure to submit them by working with the proper team!
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PROJECT VERSION\n"
"Report-Msgid-Bugs-To: apple-feedback@kde.org\n"
"POT-Creation-Date: {date.strftime("%Y-%m-%d %H:%M%z")}\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: \n"
"Language: \n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"X-Generator: KDE Connect iOS scripts\n"

"""

def xliff_text_2_po_text(xliff_text: str):
    """
    1. escape double quotes
    2. break at new lines. Note that this needs to
    introduce "" for ending and starting a new line
    3. FIXME: break at around 80 columns
    """
    return xliff_text \
        .replace('"', r'\"') \
        .replace("\n", '\\n"\n"')

def xliff2po(xliff_path: str, pot: bool = True):
    result = make_pot_header()
    tree = ET.parse(xliff_path)
    for file in tree.getroot().findall("xliff:file", NS):
        reference = file.get("original")
        for trans_unit in file.find("xliff:body", NS).findall("xliff:trans-unit", NS):
            msgctxt = xliff_text_2_po_text(trans_unit.get("id"))
            msgid = xliff_text_2_po_text(trans_unit.find("xliff:source", NS).text)
            msgstr = xliff_text_2_po_text("" if pot else trans_unit.find("xliff:target", NS).text)
            extracted_comments = trans_unit.find("xliff:note", NS).text
            objc_format = "%@" in msgid

            # output
            if extracted_comments != NO_COMMENT:
                result += f"#. {extracted_comments}\n"
            result += f"#: {reference}\n"
            if objc_format:
                result += "#, objc-format\n"
            result += f"""msgctxt "{msgctxt}"
msgid "{msgid}"
msgstr "{msgstr}"

"""
    return result

########################################
# Main
########################################

if __name__ == "__main__":
    with open("outdir/en.pot", "w") as f:
        f.write(xliff2po("outdir/en.xliff"))

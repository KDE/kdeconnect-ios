#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2022 Apollo Zhu <public-apollonian@outlook.com>
#
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

# References
# https://techbase.kde.org/Development/Tutorials/Localization/i18n_Build_Systems
# https://invent.kde.org/network/kdeconnect-android/-/blob/master/StaticMessages.sh
# https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html

# # Testing:
# # Assuming `svn co svn://anonsvn.kde.org/home/kde/trunk` at $BASEDIR
# # Assuming $BASEDIR/trunk/l10n-kf5/$LANG/messages/kdeconnect-ios/kdeconnect-ios.po exists for some $LANG
# # Assuming `git clone https://invent.kde.org/sysadmin/l10n-scripty.git` at $BASEDIR
# # Setup
# mkdir po
# export BASEDIR=../
# export transmod=trunk/l10n-kf5
# export templatename=kdeconnect-ios
# export REPACKPOT=../l10n-scripty/repack-pot.pl
# # Export pot then import po
# ../l10n-scripty/process-static-messages.sh

# The name of catalog we create (without the.pot extension), sourced from the scripty scripts
FILENAME="kdeconnect-ios"

function export_pot_file # First parameter will be the path of the pot file we have to create, includes $FILENAME
{
	potfile=$1
	mkdir outdir
	xcodebuild -exportLocalizations -project 'KDE Connect/KDE Connect.xcodeproj' -localizationPath outdir
	python3 scripts/xliff2po.py --pot -i 'outdir/en.xcloc/Localized Contents/en.xliff' -o 'outdir/template.pot'

	# Interestingly, most convertions tools cut it of around column 80 near whitespace/newline
	# where the whitespace/newline is kept at the previous line.

	# TODO: not sure how to handle plurals yet, but we don't have any stringsdict this point

	# FIXME: REPACKPOT not happy with some of the msgid, maybe need to replace `<=>` with `cmp`
	# Argument "xxx" isn't numeric in sort at repack-pot.pl line 169.
	# Argument "xxx" isn't numeric in sort at repack-pot.pl line 211.
	mv 'outdir/template.pot' $potfile
	rm -rf outdir
}

function import_po_files # First parameter will be a path that will contain several .po files with the format LANG.po
{
	podir=$1
	mkdir outdir
	# iOS probably also doesn't support languages with an @
	find "$podir" -type f -name "*@*.po" -delete
	for pofile in `ls $podir`; do
		LANG=$(basename $pofile .po)
		# FIXME: this is not picking up the right language. XLIFF should have
		# source-language="en" target-language="$LANG"
		po2xliff -i $podir/$pofile -o outdir/$LANG.xliff
		# FIXME: the translated XLIFF file has incorrect information to be imported by Xcode
		xcodebuild -importLocalizations -project 'KDE Connect/KDE Connect.xcodeproj' -localizationPath outdir/$LANG.xliff
	done
	rm -rf outdir
}

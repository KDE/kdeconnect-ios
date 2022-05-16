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
	# TODO: not sure how to handle plurals yet, but we don't have any stringsdict this point
	python3 scripts/xliff2po.py --pot -i 'outdir/en.xcloc/Localized Contents/en.xliff' -o 'outdir/template.pot'
	# FIXME: REPACKPOT expect references to have line numbers, but ... Xcode doesn't provide that
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
		python3 scripts/po2xliff.py -i $podir/$pofile -o outdir/$LANG.xliff
		xcodebuild -importLocalizations -project 'KDE Connect/KDE Connect.xcodeproj' -localizationPath outdir/$LANG.xliff
	done
	rm -rf outdir
}

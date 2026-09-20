# This is mostly empty because the actual export/import happens in StaticMessagesMac.sh, which for now we run by hand.

# The name of catalog we create (without the .pot extension), sourced from the scripty scripts
FILENAME="kdeconnect-ios"

function export_pot_file # First parameter will be a path that will contain several .po files with the format LANG.po
{
    local potfile=$1
    cp "$FILENAME.pot" $potfile
}

function import_po_files # First parameter will be a path that will contain several .po files with the format LANG.po
{
    # noop
}

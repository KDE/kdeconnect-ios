# This is mostly empty because the actual export/import happens in StaticMessagesMac.sh, which for now we run by hand.

# We use EXPORTS_POT_DIR even if we only export a single file because that allows us to create a file
# that does not have _static_ in the name and then we can keep it later
EXPORTS_POT_DIR=1
FILE_PREFIX=kdeconnect-ios

function export_pot_file # First parameter will be the path of the directory where we have to store the pot files
{
    potdir=$1
    cp kdeconnect-ios.pot $potdir
}

function import_po_dirs # First parameter will be a path that will be a directory to the dirs for each lang and then all the .po files inside
{
    : # noop
}

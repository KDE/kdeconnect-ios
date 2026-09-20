#!/usr/bin/env bash

# Needs xcode and translate-toolkit (from brew), so for now it's only ran
# manually and not as part of the scripty runs.

# The name of catalog we create (without the .pot extension), sourced from the scripty scripts
FILENAME="kdeconnect-ios"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

PROJECT="KDE Connect.xcodeproj"
SCHEME="KDE Connect"

# Xcode produces XLIFF, which we need to later convert to PO.
function _export_xliff()
{
    local destination=$1
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -exportLocalizations -localizationPath "$destination"
}

function translation_tool()
{
    local tool=$1 prefix
    if command -v "$tool" >/dev/null 2>&1; then
        command -v "$tool"
        return
    fi

    # Homebrew keeps some Translate Toolkit converters in libexec rather than
    # linking them into its bin directory.
    if command -v brew >/dev/null 2>&1; then
        prefix=$(brew --prefix translate-toolkit 2>/dev/null) || return 1
        if [ -x "$prefix/libexec/bin/$tool" ]; then
            printf '%s\n' "$prefix/libexec/bin/$tool"
            return
        fi
    fi
    return 1
}

function export_pot_file # First parameter will be the path of the pot file we have to create, includes $FILENAME
{
    local potfile=$1
    local workdir xlf po xliff2po index=0
    xliff2po=$(translation_tool xliff2po) || {
        echo "xliff2po was not found; install Translate Toolkit." >&2
        return 1
    }
    workdir=$(mktemp -d "${TMPDIR:-/tmp}/kdeconnect-ios-l10n.XXXXXX") || return

    _export_xliff "$workdir" || { rm -rf "$workdir"; return 1; }

    # Convert each XLIFF and merge them in a single pot.
    local found=0
    while IFS= read -r -d '' xlf; do
        found=1
        po="$workdir/$index.pot"
        index=$((index + 1))
        "$xliff2po" --pot --progress=none -i "$xlf" -o "$po" || {
            rm -rf "$workdir"
            return 1
        }
    done < <(find "$workdir" -type f \( -name '*.xliff' -o -name '*.xlf' \) -print0)

    if [ "$found" -eq 0 ]; then
        echo "No XLIFF files were produced by xcodebuild." >&2
        rm -rf "$workdir"
        return 1
    fi

    mkdir -p "$(dirname "$potfile")" && \
        msgcat --use-first --output-file="$potfile" "$workdir"/*.pot
    local status=$?
    if [ "$status" -eq 0 ]; then
        while IFS= read -r -d '' xlf; do
            python3 "$SCRIPT_DIR/scripts/preserve_xliff_notes.py" "$xlf" "$potfile" || {
                status=$?
                break
            }
        done < <(find "$workdir" -type f \( -name '*.xliff' -o -name '*.xlf' \) -print0)
    fi
    rm -rf "$workdir"
    return "$status"
}

function import_po_files # First parameter will be a path that will contain several .po files with the format LANG.po
{
    local podir=$1
    local workdir xlf po cleanpo language basename found=0 index
    workdir=$(mktemp -d "${TMPDIR:-/tmp}/kdeconnect-ios-l10n.XXXXXX") || return

    # Export a template, used because po2xliff can't recreate Xcode's trans-unit IDs and file metadata.
    _export_xliff "$workdir/template" || { rm -rf "$workdir"; return 1; }
    mkdir -p "$workdir/import" || { rm -rf "$workdir"; return 1; }

    while IFS= read -r -d '' po; do
        language=$(basename "$po" .po)
        index=0
        cleanpo="$workdir/${language}.po"
        # XLIFF has no representation for obsolete gettext entries.
        msgattrib --no-obsolete --output-file="$cleanpo" "$po" || {
            rm -rf "$workdir"
            return 1
        }

        while IFS= read -r -d '' xlf; do
            basename=$(basename "$xlf")
            po2xliff --progress=none -t "$xlf" -i "$cleanpo" \
                -o "$workdir/import/${language}-${index}-${basename}" || {
                rm -rf "$workdir"
                return 1
            }
            index=$((index + 1))
            found=1
        done < <(find "$workdir/template" -type f \( -name '*.xliff' -o -name '*.xlf' \) -print0)
    done < <(find "$podir" -type f -name '*.po' -print0)

    if [ "$found" -eq 0 ]; then
        echo "No PO files or XLIFF templates found." >&2
        rm -rf "$workdir"
        return 1
    fi

    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -importLocalizations -localizationPath "$workdir/import"
    local status=$?
    rm -rf "$workdir"
    return "$status"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        import)
            import_po_files "po"
            ;;
        export)
            export_pot_file "$FILENAME.pot"
            ;;
        *)
            printf 'usage: %s {import|export}\n' "$0" >&2
            exit 1
            ;;
    esac
fi

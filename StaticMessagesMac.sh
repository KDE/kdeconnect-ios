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
    shift
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -exportLocalizations -localizationPath "$destination" "$@"
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

function import_po_files # First parameter contains PO files in locale-named directories.
{
    local podir=$1
    local workdir xlf po language xcloc relative_path found=0 duplicate existing_language
    local -a languages=() export_languages=()
    workdir=$(mktemp -d "${TMPDIR:-/tmp}/kdeconnect-ios-l10n.XXXXXX") || return

    # PO files are named after the catalog, so their parent directory identifies
    # the locale (for example, po/de/kdeconnect-ios.po).
    while IFS= read -r -d '' po; do
        language=$(basename "$(dirname "$po")")
        duplicate=0
        for existing_language in "${languages[@]}"; do
            if [ "$existing_language" = "$language" ]; then
                duplicate=1
                break
            fi
        done
        if [ "$duplicate" -eq 0 ]; then
            languages+=("$language")
            export_languages+=(-exportLanguage "$language")
        fi
    done < <(find "$podir" -type f -name '*.po' -print0)

    if [ "${#languages[@]}" -eq 0 ]; then
        echo "No PO files found in $podir." >&2
        rm -rf "$workdir"
        return 1
    fi

    # Xcode imports .xcloc bundles, not a directory containing loose XLIFF
    # files. Export one template per locale to retain the target language and
    # Xcode-specific metadata.
    _export_xliff "$workdir/template" "${export_languages[@]}" || {
        rm -rf "$workdir"
        return 1
    }
    mkdir -p "$workdir/import" || { rm -rf "$workdir"; return 1; }

    while IFS= read -r -d '' po; do
        language=$(basename "$(dirname "$po")")
        xcloc="$workdir/template/${language}.xcloc"
        if [ ! -d "$xcloc" ]; then
            echo "Xcode did not export a template for locale $language." >&2
            rm -rf "$workdir"
            return 1
        fi

        cp -R "$xcloc" "$workdir/import/${language}.xcloc" || {
            rm -rf "$workdir"
            return 1
        }
        while IFS= read -r -d '' xlf; do
            relative_path=${xlf#"$xcloc/Localized Contents/"}
            python3 "$SCRIPT_DIR/scripts/apply_po_to_xliff.py" "$po" \
                "$workdir/import/${language}.xcloc/Localized Contents/$relative_path" || {
                rm -rf "$workdir"
                return 1
            }
            found=1
        done < <(find "$xcloc/Localized Contents" -type f \( -name '*.xliff' -o -name '*.xlf' \) -print0)
    done < <(find "$podir" -type f -name '*.po' -print0)

    if [ "$found" -eq 0 ]; then
        echo "No XLIFF templates were produced by xcodebuild." >&2
        rm -rf "$workdir"
        return 1
    fi

    for xcloc in "$workdir"/import/*.xcloc; do
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
            -importLocalizations -localizationPath "$xcloc" || {
            rm -rf "$workdir"
            return 1
        }
    done
    rm -rf "$workdir"
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

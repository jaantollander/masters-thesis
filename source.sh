#!/usr/bin/env bash
IN_DIR=$PWD/content
OUT_DIR=$PWD/build
ASSETS_DIR=$PWD/assets

export TEXINPUTS="::$ASSETS_DIR"

thesis_download_aaltostyle() {
    curl --location "https://wiki.aalto.fi/download/attachments/69900685/aaltothesis.cls?api=v2" --output "$ASSETS_DIR/aaltothesis.cls"
    TMP="$(mktemp -d)"
    curl --location "https://wiki.aalto.fi/download/attachments/49383512/aaltologo.zip" --output "$TMP/aaltologo.zip"
    unzip "$TMP/aaltologo.zip" -d "$TMP"
    mv "$TMP/aaltologo.sty" "$ASSETS_DIR"
}

thesis_download_citationstyle() {
    curl --location "https://raw.githubusercontent.com/citation-style-language/styles/master/harvard-anglia-ruskin-university.csl" --output "$ASSETS_DIR/citationstyle.csl"
}

thesis_html() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/"*".md"\
        --citeproc \
        --standalone \
        --from "markdown+tex_math_dollars" \
        --to "html" \
        --output "$OUT_DIR/index.html" \
        --mathjax \
        --metadata "pagetitle=Master's Thesis" \
        --metadata "date=$(date -I)" \
        --metadata-file "$ASSETS_DIR/metadata.yaml" \
        --bibliography "$ASSETS_DIR/bibliography.bib" \
        --csl "$ASSETS_DIR/citationstyle.csl"
}

thesis_pdf() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/"*".md" \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$OUT_DIR/index.pdf" \
        --pdf-engine="pdflatex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$ASSETS_DIR/metadata.yaml" \
        --bibliography "$ASSETS_DIR/bibliography.bib" \
        --csl "$ASSETS_DIR/citationstyle.csl" \
        --include-in-header "$ASSETS_DIR/header.tex"
}

thesis_tex() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/"*".md" \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$OUT_DIR/index.tex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$ASSETS_DIR/metadata.yaml" \
        --bibliography "$ASSETS_DIR/bibliography.bib" \
        --csl "$ASSETS_DIR/citationstyle.csl" \
        --include-in-header "$ASSETS_DIR/header.tex"
}

thesis_preview() {
    CMD="thesis_html"
    $CMD
    # Run html command if files in target directories change.
    # https://superuser.com/questions/181517/how-to-execute-a-command-whenever-a-file-changes
    inotifywait -e close_write,moved_to,create -m "$IN_DIR" -m "$ASSETS_DIR" |
    while read -r directory events filename; do
        case $filename in 
            *.md|*.bib) $CMD ;;
            *) ;;
        esac
    done
    unset directory events filename
}

#!/usr/bin/env bash
IN_DIR=content
OUT_DIR=build
DATA_DIR=data

thesis_download_aaltostyle() {
    curl --location "https://wiki.aalto.fi/download/attachments/69900685/aaltothesis.cls?api=v2" --output "aaltothesis.cls"
    TMP="$(mktemp -d)"
    curl --location "https://wiki.aalto.fi/download/attachments/49383512/aaltologo.zip" --output "$TMP/aaltologo.zip"
    unzip "$TMP/aaltologo.zip" -d "$TMP"
    mv "$TMP/aaltologo.sty" "."
}

thesis_html() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/"*".md"\
        --citeproc \
        --standalone \
        --from "markdown+tex_math_dollars" \
        --to "html" \
        --output "$OUT_DIR/index.html" \
        --katex \
        --metadata "pagetitle=Master's Thesis" \
        --metadata "date=$(date -I)" \
        --metadata-file "$DATA_DIR/metadata.yaml" \
        --bibliography "$DATA_DIR/bibliography.bib"
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
        --metadata-file "$DATA_DIR/metadata.yaml" \
        --bibliography "$DATA_DIR/bibliography.bib" \
        --include-in-header "$DATA_DIR/header.tex"
}

thesis_tex() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/"*".md" \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$OUT_DIR/index.tex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$DATA_DIR/metadata.yaml" \
        --bibliography "$DATA_DIR/bibliography.bib" \
        --include-in-header "$DATA_DIR/header.tex"
}

thesis_preview() {
    html
    # Run html command if files in target directories change.
    # https://superuser.com/questions/181517/how-to-execute-a-command-whenever-a-file-changes
    inotifywait -e close_write,moved_to,create -m $IN_DIR -m $DATA_DIR |
    while read -r directory events filename; do
        case $filename in 
            *.md|*.yaml|*.bib) html ;;
            *) ;;
        esac
    done
    unset directory events filename
}

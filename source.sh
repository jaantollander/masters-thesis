#!/usr/bin/env sh
IN_DIR=content
OUT_DIR=build
DATA_DIR=data

html() {
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

pdf() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/"*".md" \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$OUT_DIR/index.pdf" \
        --pdf-engine="xelatex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$DATA_DIR/metadata.yaml" \
        --bibliography "$DATA_DIR/bibliography.bib"
}

preview() {
    html
    # Run html command if files in target directories change.
    inotifywait -e close_write,moved_to,create -m $IN_DIR -m $DATA_DIR |
    while read -r directory events filename; do
        case $filename in 
            *.md|*.yaml|*.bib) html ;;
            *) ;;
        esac
    done
    unset directory events filename
}

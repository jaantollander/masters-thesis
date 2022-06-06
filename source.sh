#!/usr/bin/env sh
IN_DIR=content
OUT_DIR=build

html() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/index.md" \
        --citeproc \
        --standalone \
        --from "markdown+tex_math_dollars" \
        --to "html" \
        --output "$OUT_DIR/index.html" \
        --metadata "pagetitle=Master's Thesis" \
        --metadata "date=$(date -I)" \
        --metadata-file "metadata.yaml"
}

pdf() {
    mkdir -p "$OUT_DIR"
    pandoc "$IN_DIR/index.md" \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$OUT_DIR/index.pdf" \
        --pdf-engine="xelatex" \
        --metadata "date=$(date -I)" \
        --metadata-file "metadata.yaml"
}

#!/usr/bin/env bash
CONTENT_DIR=$PWD/content
OUT_DIR=$PWD/build
ASSETS_DIR=$PWD/assets
METADATA_DIR=$PWD/metadata
CONTAINER_PANDOC="pandoc/latex:2.19-alpine"

export TEXINPUTS="::$ASSETS_DIR"

__mdfiles() {
    find "$CONTENT_DIR" -name '*.md' | sort
}

thesis_pandoc_docker_pull() {
    sudo docker pull "$CONTAINER_PANDOC"
}

thesis_pandoc_docker_alias() {
    alias pandoc='sudo docker run --rm --volume "$(pwd):$(pwd)" --user $(id -u):$(id -g) "$CONTAINER_PANDOC"'
}

thesis_download_aaltostyle() {
    curl --location "https://wiki.aalto.fi/download/attachments/69900685/aaltothesis.cls?api=v2" --output "$ASSETS_DIR/aaltothesis.cls"
    TMP="$(mktemp -d)"
    curl --location "https://wiki.aalto.fi/download/attachments/49383512/aaltologo.zip" --output "$TMP/aaltologo.zip"
    unzip "$TMP/aaltologo.zip" -d "$TMP"
    mv "$TMP/aaltologo.sty" "$ASSETS_DIR"
}

thesis_download_citationstyle() {
    curl --location "https://raw.githubusercontent.com/citation-style-language/styles/master/vancouver-brackets.csl" --output "$ASSETS_DIR/citationstyle.csl"
}

thesis_html() {
    mkdir -p "$OUT_DIR"
    pandoc $(__mdfiles) \
        --citeproc \
        --standalone \
        --from "markdown+tex_math_dollars" \
        --to "html" \
        --output "$OUT_DIR/index.html" \
        --mathjax \
        --metadata "date=$(date -I)" \
        --metadata-file "$METADATA_DIR/html.yaml" \
        --bibliography "$CONTENT_DIR/bibliography.bib" \
        --csl "$ASSETS_DIR/citationstyle.csl" \
        --toc \
        --number-sections
}

thesis_epub() {
    mkdir -p "$OUT_DIR"
    pandoc $(__mdfiles) \
        --citeproc \
        --from "markdown+tex_math_dollars" \
        --to "epub" \
        --output "$OUT_DIR/index.epub" \
        --mathml \
        --metadata "date=$(date -I)" \
        --metadata-file "$METADATA_DIR/epub.yaml" \
        --bibliography "$CONTENT_DIR/bibliography.bib" \
        --csl "$ASSETS_DIR/citationstyle.csl" \
        --toc \
        --number-sections
}

thesis_pdf() {
    mkdir -p "$OUT_DIR"
    pandoc $(__mdfiles) \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$OUT_DIR/index.pdf" \
        --pdf-engine="pdflatex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$METADATA_DIR/tex.yaml" \
        --bibliography "$CONTENT_DIR/bibliography.bib" \
        --csl "$ASSETS_DIR/citationstyle.csl" \
        --include-in-header "$CONTENT_DIR/header.tex" \
        --include-before-body "$CONTENT_DIR/body.tex" \
        --number-sections
}

thesis_tex() {
    mkdir -p "$OUT_DIR"
    pandoc $(__mdfiles) \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$OUT_DIR/index.tex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$METADATA_DIR/tex.yaml" \
        --bibliography "$CONTENT_DIR/bibliography.bib" \
        --csl "$ASSETS_DIR/citationstyle.csl" \
        --include-in-header "$CONTENT_DIR/header.tex" \
        --include-before-body "$CONTENT_DIR/body.tex" \
        --number-sections
}

thesis_preview() {
    THESIS_PREVIEW_CMD=$1
    case "$THESIS_PREVIEW_CMD" in
        thesis_pdf|thesis_epub|thesis_html) ;;
        *) exit 1 ;;
    esac

    # Run command initially before watching changes.
    $THESIS_PREVIEW_CMD

    # Run "THESIS_PREVIEW_CMD" if files in target directories change.
    # https://superuser.com/questions/181517/how-to-execute-a-command-whenever-a-file-changes
    inotifywait -e close_write,moved_to,create -m "$CONTENT_DIR" -m "$METADATA_DIR" |
    while read -r directory events filename; do
        case $filename in 
            *.md|*.bib|*.tex|*.yaml) $THESIS_PREVIEW_CMD ;;
            *) ;;
        esac
    done
    unset directory events filename
}

thesis_serve() {
    julia serve.jl "$OUT_DIR"
}

thesis_build() {
    git stash -u && \
    git checkout  --orphan "build" && \
    thesis_pdf && thesis_epub && thesis_html && mv "$BUILD_DIR"/* . && \
    git rm -rf . && \
    git add . && \
    git commit -m "build" && \
    git push "origin" "build" --force && \
    git checkout "master" && \
    git branch -D "build" && \
    git stash pop
}

#!/usr/bin/env bash
# USAGE:
#    source env.sh
#    thesis_pdf

dir_content() { echo "$PWD/content"; }
dir_figures() { echo "$PWD/content/figures"; }
dir_assets() { echo "$PWD/assets"; }
dir_metadata() { echo "$PWD/metadata"; }

dir_out() {
    DIR_OUT=$1
    : "${DIR_OUT:="$PWD/build"}"
    mkdir -p "$DIR_OUT"
    echo "$DIR_OUT"
}

files_md() { find "$(dir_content)" -name '*.md' | sort ;}

thesis_download_aaltostyle() {
    curl --location "https://wiki.aalto.fi/download/attachments/69900685/aaltothesis.cls?api=v2" \
        --output "$(dir_assets)/aaltothesis.cls"
    TMP="$(mktemp -d)"
    curl --location "https://wiki.aalto.fi/download/attachments/49383512/aaltologo.zip" \
        --output "$TMP/aaltologo.zip"
    unzip "$TMP/aaltologo.zip" -d "$TMP"
    mv "$TMP/aaltologo.sty" "$(dir_assets)"
}

thesis_download_citationstyle() {
    curl --location "https://raw.githubusercontent.com/citation-style-language/styles/master/vancouver-brackets.csl" \
        --output "$(dir_assets)/citationstyle.csl"
}

thesis_html() {
    DIR_OUT=$(dir_out "$1")
    cp -r "$(dir_figures)" "$DIR_OUT"
    pandoc $(files_md) \
        --resource-path="$(dir_content)" \
        --citeproc \
        --standalone \
        --from "markdown+tex_math_dollars" \
        --to "html" \
        --output "$DIR_OUT/index.html" \
        --mathjax \
        --metadata "date=$(date -I)" \
        --metadata-file "$(dir_metadata)/html.yaml" \
        --bibliography "$(dir_content)/bibliography.bib" \
        --csl "$(dir_assets)/citationstyle.csl" \
        --toc \
        --number-sections \
        --toc-depth 2 \
        --strip-comments
}

thesis_epub() {
    DIR_OUT=$(dir_out "$1")
    pandoc $(files_md) \
        --resource-path="$(dir_content)" \
        --citeproc \
        --from "markdown+tex_math_dollars" \
        --to "epub" \
        --output "$DIR_OUT/sci_2022_tollander-de-balsch_jaan.epub" \
        --mathml \
        --metadata "date=$(date -I)" \
        --metadata-file "$(dir_metadata)/epub.yaml" \
        --bibliography "$(dir_content)/bibliography.bib" \
        --csl "$(dir_assets)/citationstyle.csl" \
        --toc \
        --number-sections \
        --toc-depth 2 \
        --strip-comments
}

thesis_pdf() {
    TEXINPUTS="::$(dir_assets)"
    export TEXINPUTS
    DIR_OUT=$(dir_out "$1")
    pandoc $(files_md) \
        --resource-path="$(dir_content)" \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$DIR_OUT/sci_2022_tollander-de-balsch_jaan.pdf" \
        --pdf-engine="pdflatex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$(dir_metadata)/tex.yaml" \
        --bibliography "$(dir_content)/bibliography.bib" \
        --csl "$(dir_assets)/citationstyle.csl" \
        --include-in-header "$(dir_content)/header.tex" \
        --include-before-body "$(dir_content)/body.tex" \
        --number-sections \
        --toc-depth 2 \
        --strip-comments \
        --top-level-division="section"
}

thesis_tex() {
    DIR_OUT=$(dir_out "$1")
    pandoc $(files_md) \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$DIR_OUT/sci_2022_tollander-de-balsch_jaan.tex" \
        --metadata "date=$(date -I)" \
        --metadata-file "$(dir_metadata)/tex.yaml" \
        --bibliography "$(dir_content)/bibliography.bib" \
        --csl "$(dir_assets)/citationstyle.csl" \
        --include-in-header "$(dir_content)/header.tex" \
        --include-before-body "$(dir_content)/body.tex" \
        --number-sections \
        --toc-depth 2 \
        --strip-comments \
        --top-level-division="section"
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
    inotifywait -e close_write,moved_to,create -m "$(dir_content)" -m "$(dir_metadata)" |
    while read -r directory events filename; do
        case $filename in 
            *.md|*.bib|*.tex|*.yaml) $THESIS_PREVIEW_CMD ;;
            *) ;;
        esac
    done
    unset directory events filename
}

thesis_serve() {
    julia serve.jl "$(dir_out)"
}

thesis_build() {
    TMP=$(mktemp -d)
    echo "$TMP"
    cp -r .git "$TMP"

    (
        cd "$TMP" && \
        git checkout  --orphan "build" && \
        git rm -rf .
    )

    thesis_pdf "$TMP"
    thesis_epub "$TMP"
    #thesis_html "$TMP"
    #thesis_tex "$TMP"

    (
        cd "$TMP" && \
        git add . && \
        git commit -m "build" && \
        git push "origin" "build" --force
    )
}

DOCKER_PANDOC="pandoc/latex:2.19-alpine"

thesis_pandoc_docker_pull() {
    sudo docker pull "$DOCKER_PANDOC"
}

thesis_pandoc_docker_alias() {
    alias pandoc='sudo docker run --rm --volume "$(pwd):$(pwd)" --user $(id -u):$(id -g) "$DOCKER_PANDOC"'
}

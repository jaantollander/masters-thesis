#!/usr/bin/env bash
# USAGE:
#    source env.sh
#    thesis_pdf

CONTAINER_PANDOC="pandoc/latex:2.19-alpine"

thesis_pandoc_docker_pull() {
    sudo docker pull "$CONTAINER_PANDOC"
}

thesis_pandoc_docker_alias() {
    alias pandoc='sudo docker run --rm --volume "$(pwd):$(pwd)" --user $(id -u):$(id -g) "$CONTAINER_PANDOC"'
}


dir_content() { echo "$PWD/content"; }
dir_figures() { echo "$PWD/content/figures"; }
dir_assets() { echo "$PWD/assets"; }
dir_metadata() { echo "$PWD/metadata"; }
dir_out() { echo "$PWD/build"; }

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

thesis_copy_figures() {
    cp -r "$(dir_figures)" "$(dir_out)"
}

thesis_html() {
    mkdir -p "$(dir_out)"
    thesis_copy_figures
    pandoc $(files_md) \
        --resource-path="$(dir_content)" \
        --citeproc \
        --standalone \
        --from "markdown+tex_math_dollars" \
        --to "html" \
        --output "$(dir_out)/index.html" \
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
    mkdir -p "$(dir_out)"
    pandoc $(files_md) \
        --resource-path="$(dir_content)" \
        --citeproc \
        --from "markdown+tex_math_dollars" \
        --to "epub" \
        --output "$(dir_out)/sci_2022_tollander-de-balsch_jaan.epub" \
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
    mkdir -p "$(dir_out)"
    pandoc $(files_md) \
        --resource-path="$(dir_content)" \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$(dir_out)/sci_2022_tollander-de-balsch_jaan.pdf" \
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
    mkdir -p "$(dir_out)"
    pandoc $(files_md) \
        --citeproc \
        --from "markdown+tex_math_dollars+raw_tex" \
        --to "latex" \
        --output "$(dir_out)/sci_2022_tollander-de-balsch_jaan.tex" \
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
    # Run in subshell
    (
        TMP=$(mktemp -d) && \
        echo "$TMP" && \
        cp -r . "$TMP" && \
        cd "$TMP" && \
        git checkout  --orphan "build" && \
        thesis_pdf && \
        thesis_epub && \
        thesis_html && \
        thesis_tex && \
        mv "$(dir_out)"/* . && \
        git rm -rf . && \
        git add . && \
        git commit -m "build" && \
        git push "origin" "build" --force
    )
}


#!/usr/bin/env bash
CONTAINER_PANDOC="pandoc/latex:2.19-alpine"

thesis_pandoc_docker_pull() {
    sudo docker pull "$CONTAINER_PANDOC"
}

thesis_pandoc_docker_alias() {
    alias pandoc='sudo docker run --rm --volume "$(pwd):$(pwd)" --user $(id -u):$(id -g) "$CONTAINER_PANDOC"'
}

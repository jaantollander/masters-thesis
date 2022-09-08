#!/usr/bin/env bash
cat /etc/redhat-release > puhti-versions.txt
lctl lustre_build_version >> puhti-versions.txt
sinfo --version >> puhti-versions.txt
scontrol show partitions --all > puhti-partitions.txt
scontrol show node --all > puhti-nodes.txt

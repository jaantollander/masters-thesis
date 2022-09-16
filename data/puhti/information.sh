#!/usr/bin/env bash
cat /etc/redhat-release > versions.txt
lctl lustre_build_version >> versions.txt
sinfo --version >> versions.txt
scontrol show partitions --all > slurm-partitions.txt
scontrol show node --all > compute-nodes.txt
grep 'NodeName=' compute-nodes.txt | cut -c 10-15 | sort > compute-nodenames.csv

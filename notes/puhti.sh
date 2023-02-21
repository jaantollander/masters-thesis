#!/usr/bin/env bash
mkdir -p puhti
ssh puhti -t 'cat /proc/version' > puhti/version
ssh puhti -t 'cat /etc/redhat-release' > puhti/redhat-release
ssh puhti -t 'lctl lustre_build_version' > puhti/lustre-version
ssh puhti -t 'lctl get_param jobid_var jobid_name' > puhti/lustre-params
ssh puhti -t 'cat /etc/hosts' > puhti/hosts
ssh puhti -t 'sinfo --version' > puhti/slurm-version
ssh puhti -t 'scontrol show partitions --all' > puhti/slurm-partitions
ssh puhti -t 'scontrol show node --all' > puhti/slurm-nodes
#grep 'NodeName=' compute-nodes.txt | cut -c 10-15 | sort > compute-nodenames.csv

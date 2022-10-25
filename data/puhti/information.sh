#!/usr/bin/env bash
cat /proc/version > information.txt
cat /etc/redhat-release >> information.txt
lctl lustre_build_version >> information.txt
sinfo --version >> information.txt
scontrol show partitions --all > slurm-partitions.txt
scontrol show node --all > compute-nodes.txt
grep 'NodeName=' compute-nodes.txt | cut -c 10-15 | sort > compute-nodenames.csv
lctl get_param jobid_var jobid_name > information.txt

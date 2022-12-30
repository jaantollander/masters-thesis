#!/usr/bin/env bash
# TODO: execute via ssh on puhti
{
cat /proc/version;
echo;
cat /etc/redhat-release;
echo;
lctl lustre_build_version;
lctl get_param jobid_var jobid_name;
echo;
sinfo --version;
} > information.txt

cat /etc/hosts > hosts.txt

scontrol show partitions --all > slurm-partitions.txt
scontrol show node --all > compute-nodes.txt
grep 'NodeName=' compute-nodes.txt | cut -c 10-15 | sort > compute-nodenames.csv

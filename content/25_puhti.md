\newpage

# Puhti cluster at CSC
## Overview

## Hardware configuration

Node category | Node type | Node count | Memory \newline (GiB per node) | Local storage \newline (GiB per node)
-|-|-|-|-
*Service* | *Utility* | 3 | 384 | 2900
*Service* | *Login* | 2 | 384 | 2900
*Service* | *Login-FMI* | 2 | 384 | 2900
*Service* | *Lustre-MDS* | 2 |   |  
*Service* | *Lustre-OSS* | 4 |   |  
*Compute* | *CPU*, *M* | 484 | 192 | -
*Compute* | *CPU*, *M-IO* | 48 | 192 | 1490
*Compute* | *CPU*, *M-FMI* | 240 | 192 | -
*Compute* | *CPU*, *L* | 92 | 384 | -
*Compute* | *CPU*, *L-IO* | 40 | 384 | 3600
*Compute* | *CPU*, *XL* | 12 | 768 | 1490
*Compute* | *CPU*, *BM* | 6 | 1500 | 5960
*Compute* | *GPU* | 80 | 384 | 3600

: \label{tab:puhti-nodes}
Nodes counts by type and category on the Puhti cluster.

The *Puhti* cluster has various *service nodes* and 1002 *compute nodes* as seen on the table \ref{tab:puhti-nodes}.
The services nodes consist of *utility nodes* for development and administration, *login nodes* for users to login to the system and MDS and OSS nodes for the Lustre file system.
The compute nodes consist of 922 *CPU nodes* and 80 *GPU nodes*.
Each login and compute node consists of two *Intel Xeon Gold 6230* CPUs with 20 cores and 2.1 GHz base frequency.
In addition to CPUs, each GPU node has four *Nvidia Volta V100* GPUs and each GPU has 36 GiB of GPU memory.
We give compute nodes types based on how much memory (RAM) and *fast local storage* they contain, and whether they contains GPUs.
Fast local storage is a Solid State Disk (SSD) attached to the node via *Non-Volative Memory Express (NVMe)* to perform I/O intensive processes instead of having to rely on the global storage from the Lustre file system.

The global storage on Puhti consists of a Lustre file system, version 2.12.6 from *DataDirect Networks (DDN)*, that has 2 MDSs and 8 virtualized OSSs with ES18K controller.
Each MDS has 2 MDTs on each server connected to 20 $\times$ 800 GB NVMe.
Each OSS has 3 OSTs on each server connected to 704 $\times$ 10 TB SAS HDD.
The total storage capacity of the file system is 4.8 PBs since part of the total capacity is reserved for redundancy.

The network configuration is presented on the figure \ref{fig:puhti-network}.

![
High-level overview of the network connections in the Puhti cluster.
Every node is connected to every L1 switch, and every L1 switch is connected to every L2 switch.
The nodes are connected using *Mellanox HDR InfiniBand* (100 GB/s IB HDR100) to L1 switches which are connected to L2 switches in a *fat-tree* network topology.
The network has a total of 28 L1 switches and 12 L2 switches.
\label{fig:puhti-network}
](figures/puhti-hardware.drawio.svg)


## System configuration
Puhti uses the *RedHat Enterprise Linux Server* as its operating system.
The version transitioned from 7.9 to 8.6 during the thesis writing.
Each node in Puhti has a *hostname* in the form `<nodename>.bullx`.
The format of the *node name* string using Perl compatible regular expression syntax is **`puhti-[[:alnum:]_-]+`** for utility nodes and **`r[0-9]{2}[c,m,g][0-9]{2}`** for compute nodes.
For example, `puhti-login12.bullx` or `r01c01.bullx`.
We can use node names to track file system operations in node specific level.

In CSC systems, users have a *user account* which can belong to one or more *projects*.
Projects are used for setting quotas and accounting of computational resources and storage.
The usage of computational resources is measured using *Billing Units (BU)*.
Different rates of billing unit usage are set to resources including reserved CPU cores, memory, local disk, and GPUs.
[@cscdocs]

In Puhti, each user account is associated with a *user* and each project with a *group*.
We can use user IDs (UID) and group IDs (GID) as identifiers for measuring file system usage in user or group level.
We should note that, UIDs from 0 to 999 to are reserved for system processes.
For example, 0 is root and 666 is job control.
It is useful to separate the file system operations performed by system UIDs from the other UIDS.

File system is separated to *storage areas*.
Each storage area has a dedicated directory.
The global, Lustre file system is shared across *home*, *projappl*, and *scratch* storage areas with different uses and quotas.

*home*
: area is intended for storing personal data and configuration files.
In the file system, it resides at `/users/<user>` available via the `$HOME` variable and has a default quota of 10 GB per user.

*projappl*
: area is intended for storing project-specific application files such as compiled libraries.
It resides at `/projappl/<project>` and has a default quota of 50 GB per project.

*scratch*
: area is intended for short-term storage of data used in the cluster.
It resides at `/scratch/<project>` and has a default quota of 1 TB per project.
Files that require long-term storage should be moved to a long-term data storage outside Puhti.

Jobs should use the *scratch* area for storing data.
They should access *home* or *projappl* areas only to read or copy configuration files or application specific files in the beginning of the job.

There are two local storage areas, *local scratch* and *tmp*, that are intended for temporary file storage for I/O heavy operations.
User should copy data that they wish to keep after the job has completed to *scratch* since files in these temporary storage areas are cleaned regularly.

*local scratch*
: is an area for batch jobs to perform I/O heavy operations.
It is mounted on local SSD.
The quota depends on how much is requested for the job.
It resides at `/run/nvme/job_<jobid>/data` available via the `$LOCAL_SCRATCH` variable.

*tmp*
: is an area for login and interactive jobs to perform I/O heavy operations such as post and preprocessing of data, compiling libraries, or compressing data.
It is mounted on RAMDisk.
It resides at `/local_scratch/<user>` available via the `$TMPDIR` variable.


## Running workloads
Partition name | Time limit | Task limit | Node limit | Node type
-|-|-|-|-|-|-
*test* | 15 minutes | 80 | 2 | *M*
*interactive* | 7 days | 8 | 1 | *M-IO*, *L-IO*
*small* | 3 days |  40 | 1 | *M*, *L*, *M-IO*, *L-IO*
*large* | 3 days | 1040 | 26 | *M*, *L*, *M-IO*, *L-IO*
*longrun* | 14 days | 40 | 1 | *M*, *L*, *M-IO*, *L-IO*
*hugemem* | 3 days | 160 | 4 | *XL*, *BM*
*hugemem\_longrun* | 14 days | 40 | 1 | *XL*, *BM*
*fmitest* | 1 hour | 80 | 2 | *M-FMI*
*fmi* | 12 days | 4000 | 100 | *M-FMI*
*gputest* | 15 minutes | 8 | 2 | *GPU*
*gpu* | 3 days | 80 | 20 | *GPU*

: \label{tab:slurm-partitions}
Slurm partitions on Puhti.

Puhti uses Slurm version 21.08.7 as a worload manager.
It has partitions with different resource limits as seen on table \ref{tab:slurm-partitions}.
When we submit a job to Slurm, we must specify in which partition it will run, the project which used for billing, and the resource we wish to reserve.
Slurm schedules the job to run when sufficient resource are available using a fair share algorithm.
It sets different job specific environment variables for each job such that programs can access and use the job information within the process.
We can use the *Slurm job identifier* (`SLURM_JOB_ID` environment variable) as identifier to collect job specific file operations.
Slurm also performs accounting of other details about the submitted jobs.
See examples of Slurm job scripts in the appendix \ref{slurm-job-scripts}.


## Issues with parallel file system
[@tacc-io-guideline]


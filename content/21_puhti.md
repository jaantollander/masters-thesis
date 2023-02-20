## Puhti cluster at CSC
In order to build a monitoring system for CSC's Puhti cluster, we need to understand certain aspects of its hardware and software configuration.
Puhti is a Petascale system, referring to the peak performance above $10^{15}$ floating point operations per second.
It has over five hundred unique monthly users and a diverse user base, making it prone to problems from heavy use of the parallel file system, and thus interesting for studying.
Puhti is a Finnish noun that means having energy.
We explain the hardware configuration of Puhti, including the nodes, processors, memory, storage, and network.
Then, we cover the system configuration, such as the operating system, specific names and identifiers, and storage areas.

Value    | Prefix   | Value    | Prefix
-        | -        | -        | -
$1000^1$ | kilo (k) | $1024^1$ | kibi (Ki)
$1000^2$ | mega (M) | $1024^2$ | mebi (Mi)
$1000^3$ | giga (G) | $1024^3$ | gibi (Gi)
$1000^4$ | tera (T) | $1024^4$ | tebi (Ti)
$1000^5$ | peta (P) | $1024^5$ | pebi (Pi)

: \label{tab:prefixes}
Prefixes of units in base ten and base two.

We use units of bytes and bits and base ten and base two prefixes, as shown in Table \ref{tab:prefixes}.
One byte (B) is eight bits (b).
Units of memory size use bytes with base two prefixes, such as gibibytes (GiB), storage size uses bytes with base ten prefixes, such as gigabytes (GB), and network bandwidth uses bit rates with base ten prefixes, such as gigabits per second (Gb/s).


Node category | Node type | Node count | Memory \newline (GiB per node) | Local storage \newline (GB per node)
-|-|-|-|-
Lustre | MDS (virtual) | 2 |   |  
Lustre | OSS (virtual) | 8 |   |  
Service | Utility | 3 | 384 | 2900
Service | Login | 2 | 384 | 2900
Service | Login-FMI | 2 | 384 | 2900
Compute | CPU, M | 484 | 192 | -
Compute | CPU, M-IO | 48 | 192 | 1490
Compute | CPU, M-FMI | 240 | 192 | -
Compute | CPU, L | 92 | 384 | -
Compute | CPU, L-IO | 40 | 384 | 3600
Compute | CPU, XL | 12 | 768 | 1490
Compute | CPU, BM | 6 | 1500 | 5960
Compute | GPU | 80 | 384 | 3600

: \label{tab:puhti-nodes}
Nodes on the Puhti cluster.
Puhti has different node categories based on their function in the cluster.
Lustre nodes serve the Lustre file system, service nodes form the front end and serve utility functions, and compute nodes form the back end of the cluster.
Each node category contains different node types, and each node of a given type has identical resources, such as processor, memory, and local storage.
The node count describes how many nodes of a given type Puhti contains.


The *Puhti* cluster has various *service nodes* and 1002 *compute nodes* as seen in Table \ref{tab:puhti-nodes}.
The services nodes consist of *utility nodes* for development and administration, *login nodes* for users to log in to the system, and MDS and OSS nodes for the Lustre file system.
The compute nodes consist of 922 CPU nodes and 80 GPU nodes.
Each login and compute node consists of two Intel Xeon Gold 6230 Central Processing Units (CPUs) with 20 cores and 2.1 GHz base frequency.
In addition to CPUs, each GPU node has four Nvidia Volta V100 Graphical Processing Units (GPUs), and each GPU has 36 GiB of GPU memory.
We type nodes based on how much Random-access Memory (RAM) and *fast local storage* they contain and whether they contain GPUs.
Fast local storage is a Solid State Disk (SSD) attached to the node via Non-Volatile Memory Express (NVMe) for processes to perform I/O intensive work instead of relying on the system-wide storage.

The system-wide storage on Puhti consists of a Lustre parallel file system, introduced in Section \ref{lustre-parallel-file-system}.
At the time of writing, Puhti has Lustre version 2.12.6 from DataDirect Networks (DDN).
Puhti's Lustre configuration contains two virtualized MDSs and eight virtualized OSSs with an SFA18KE controller.
Each MDS has two MDTs.
All four MDTs share 20 of 800 GB NVMe via Linux Volume Manager (LVM).
Each OSS has three OSTs.
Each OST is connected to 30 of 10 TB SAS HDD.
The total storage capacity of the file system is 4.8 PBs since part of the total capacity is reserved for redundancy.

The cluster connects nodes via a network with an HDR200 fat-tree topology.
Each node connects to one of 28 L1 switches in the network, and each L1 switch connects to all 12 L2 switches.
The connections use Mellanox HDR InfiniBand (100 Gb/s IB HDR100).
Figure \ref{fig:puhti-network} shows a simplified, high-level overview of the network.

![
Puhti's configuration from a storage perspective.
Rounded rectangles on the left illustrate compute, utility, and login nodes, whereas the dashed rectangles below are the optional attached local storage.
Rounded rectangles on the right illustrate the Lustre servers, where the rectangles below are the appropriate Lustre targets.
The lines represent the network connections, and the circles represent the network switches.
Three dots between nodes or switches indicate that there are many of them.
\label{fig:puhti-network}
](figures/puhti-hardware.drawio.svg)

<!-- TODO: illustrate that there are two MDTs per MDS and three OSTs per OSS in the figure -->

As mentioned in Section \ref{linux-operating-system}, most high-performance clusters use the Linux operating system.
Puhti also uses Linux as its operating system, specifically the RedHat Enterprise Linux Server (RHEL) distribution which transitioned from version 7.9 to 8.6 during the thesis writing.

<!-- TODO: expand discussion -->
Each Lustre server and target has a name in the Lustre file system.
We record file system usage statistics for each target.
Table \ref{tab:lustre-servers-targets} lists the names of Lustre targets for the corresponding Lustre server in Puhti.
We denote set such that curly braces `{...}` denote a set, ranges such as `{01-04}` expand to `{01,02,03,04}`, and products such as `{a,b}{c,d}` expand to `{ac,ad,bc,bd}`.
Furthermore, we add curly braces to elements outside them, such as `a{c,b}` is `{a}{c,b}` and expand them as a product.


Node category|Node Type|Index|Targets
-|-|-|-
Lustre|MDS|1|`scratch-MDT{0000,0001}`
Lustre|MDS|2|`scratch-MDT{0002,0003}`
Lustre|OSS|1|`scratch-OST{0000,0001,0002}`
Lustre|OSS|2|`scratch-OST{0003,0004,0005}`
Lustre|OSS|3|`scratch-OST{0006,0007,0008}`
Lustre|OSS|4|`scratch-OST{0009,000a,000b}`
Lustre|OSS|5|`scratch-OST{000c,000d,000e}`
Lustre|OSS|6|`scratch-OST{000f,0010,0011}`
Lustre|OSS|7|`scratch-OST{0012,0013,0014}`
Lustre|OSS|8|`scratch-OST{0015,0016,0017}`

: \label{tab:lustre-servers-targets}
Names of Lustre servers and Lustre targets in Puhti.
For example, `scratch-MDT0000` is the name of one of the MDTs, and `scratch-OST000f` is the name of one of the OSTs.
The prefix `scratch-` is the mount point for Lustre directories under the root directory, `/scratch/`.
We should not confuse it with the Scratch storage area discussed later, which is mounted under the scratch directory `/scratch/scratch/`.


Each node in Puhti is a Lustre client of the shared Lustre file system.
We can identify nodes based on their *node name*, which is part of the hostname before the first dot, for example, `<nodename>.bullx`.
Table \ref{tab:node-names} lists the names of service and compute nodes.
We can use node names to separate file system operations at a node-specific level.


Node category | Set of node names
-|-
Service | `puhti-login{11-16}`
Service | `puhti-fmi{11-12}`
Service | `puhti-ood1-{production}`
Service | `puhti-ood2-{testing,production}`
Compute | `r{01-04}c{01-48}`
Compute | `r{01-04}g{01-08}`
Compute | `r{05-07}c{01-64}`
Compute | `r08m{01-06}`
Compute | `r{09-10}c{01-48}`
Compute | `r{11-12}c{01-72}`
Compute | `r{13-18}c{01-48}`
Compute | `r{13-18}g{01-08}`

: \label{tab:node-names}
Names of service and compute nodes in Puhti that have Lustre Jobstats enabled.
For example, `puhti-login11` is the name of one of the login nodes, and `r01c21` is the name of one of the compute nodes.


Puhti separates its file system into storage areas such that each storage area has a dedicated directory.
It shares the same Lustre file system across Home, Projappl, and Scratch storage areas with different uses and quotas.

- Home is intended for storing personal data and configuration files with a fixed quota of 10 GB and 100 000 files per user.

- Projappl is intended for storing project-specific application files such as compiled libraries with a default quota of 50 GB and 100 000 files per project.

- Scratch is intended for short-term data storage in the cluster with a default quota of 1 TB and 1 000 000 files per project.

As a general guideline, jobs should use the Scratch area for storing data.
They should access the Home or Projappl areas only to read or copy configuration or application-specific files at the beginning of the job.

Puhti also has two local storage areas, Local scratch, and Tmp.
They are intended for temporary file storage for I/O heavy operations to avoid burdening the Lustre file system.
Users who want to keep data from local storage after a job completion must copy it to scratch since the system regularly cleans the local storage areas.

- Local scratch, mounted on a local SSD, is indented for batch jobs to perform I/O heavy operations.
Its quota depends on how much the user requests for the job.

- Tmp, mounted on RAMDisk, is intended for login and interactive jobs to perform I/O heavy operations such as post and preprocessing data, compiling libraries, or compressing data.

In CSC systems, users have a user account that can belong to one or more *projects*.
We use projects for setting quotas and accounting for computational resources and storage.
<!--
We measure the usage of computational resources in Billing Units (BU).
Resources, such as reserved CPU cores, memory, local disk, GPUs, and storage, use different rates of BUs.
-->
Puhti associates each user account with a *user* and each project with a *group*.
We can use user IDs to measure file system usage at the user level.
However, we should retrieve the group ID from the workload manager's accounting as a project ID.
RHEL 7 and 8 reserve user IDs from 0 to 999 for system processes.
We refer to the users with IDs from 0 to 999 as *system users* and other users as *non-system users*.
It is helpful to separate the file system operations performed by system users from the non-system users.
In this work, we care more about measuring the file system usage from non-system users.

<!--  TODO: login vs compute -->

Puhti uses the Slurm workload manager, introduced in Section \ref{slurm-workload-manager}.
At the time of writing, the version was 21.08.7, but it is updated regularly.
It has partitions with different resource limits, set by administrators, as seen in Table \ref{tab:slurm-partitions}.
When we submit a job to Slurm, we must specify which partition it will run, the project used for billing, and the resource we want to reserve.
We present concrete examples of Slurm job scripts for Puhti in Appendix \ref{slurm-job-scripts}.
Slurm schedules the job to run when sufficient resources are available using a fair share algorithm.
It also performs accounting of details about the submitted jobs.


Partition name | Time limit | Task limit | Node limit | Node type
-|-|-|-|-|-|-
`test` | 15 minutes | 80 | 2 | M
`interactive` | 7 days | 8 | 1 | M-IO, L-IO
`small` | 3 days |  40 | 1 | M, L, M-IO, L-IO
`large` | 3 days | 1040 | 26 | M, L, M-IO, L-IO
`longrun` | 14 days | 40 | 1 | M, L, M-IO, L-IO
`hugemem` | 3 days | 160 | 4 | XL, BM
`hugemem_longrun` | 14 days | 40 | 1 | XL, BM
`fmitest` | 1 hour | 80 | 2 | M-FMI
`fmi` | 12 days | 4000 | 100 | M-FMI
`gputest` | 15 minutes | 8 | 2 | GPU
`gpu` | 3 days | 80 | 20 | GPU

: \label{tab:slurm-partitions}
Slurm partitions on Puhti at the time of writing.
Each partition has a name and resource limits such as time, task, and node limit that a job can request on the partition.
Node types, listed in Table \ref{tab:puhti-nodes}, dictate the nodes where a job may run.
Typically, memory and local storage limits are the same for the node type.


Slurm sets different job-specific environment variables for each job such that programs can access and use them.
An important environment variable is the *Slurm Job ID*, accessed via `SLURM_JOB_ID`, which we use as an identifier to collect job-specific file operations.
We can combine the data from Slurm's accounting with the file system usage using the job ID.
For example, we can use the information about the project, partition, and local storage reservation of a job.
Project information might help identify if members of a particular project perform problematic file I/O patterns.


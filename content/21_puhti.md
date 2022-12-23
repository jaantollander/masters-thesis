\clearpage

# Puhti cluster at CSC
This section presents the configuration of the *Puhti* cluster, a Petascale system operated by CSC in Finland, from a storage perspective.
Petascale refers to the peak performance of $10^{15}$ floating point operations per second.
It has over five hundred unique monthly users and a diverse user base, making it interesting for studying file system usage.
Puhti is a Finnish noun that means having energy.
*CSC -- The IT Center for Science* is an organization that provides ICT services for higher education institutions, research institutes, culture, public administration, and enterprises in Finland.
The services include high-performance computing, cloud computing, data storage, network services, training, and technical support. [@about-csc]

In Subsection \ref{hardware-configuration}, we explain the hardware configuration of Puhti, including the nodes, processors, memory, storage, and network.
Subsection \ref{system-configuration} covers the system configuration, such as the operating system, specific names and identifiers, and storage areas.
Finally, Subsection \ref{running-workloads} discusses how to workloads on Puhti via Slurm, Slurm partitions, and Slurm's relevance for collecting file system usage statistics.

Value    | Prefix   | Value    | Prefix
-        | -        | -        | -
$1000^1$ | kilo (k) | $1024^1$ | kibi (Ki)
$1000^2$ | mega (M) | $1024^2$ | mebi (Mi)
$1000^3$ | giga (G) | $1024^3$ | gibi (Gi)
$1000^4$ | tera (T) | $1024^4$ | tebi (Ti)
$1000^5$ | peta (P) | $1024^5$ | pebi (Pi)

: \label{tab:prefixes}
  Prefixes in base ten and base two.

In this section, we use units of bytes and bits and base ten and base two prefixes, as shown in Table \ref{tab:prefixes}.
One byte (B) is eight bits (b).
Units of memory size use bytes with base two prefixes, such as gibibytes (GiB), storage size uses bytes with base ten prefixes, such as gigabytes (GB), and network bandwidth uses bit rates with base ten prefixes, such as gigabits per second (Gb/s).

\clearpage

## Hardware configuration

Node category | Node type | Node count | Memory \newline (GiB per node) | Local storage \newline (GB per node)
-|-|-|-|-
*Lustre* | *MDS* (virtual) | 2 |   |  
*Lustre* | *OSS* (virtual) | 8 |   |  
*Service* | *Utility* | 3 | 384 | 2900
*Service* | *Login* | 2 | 384 | 2900
*Service* | *Login-FMI* | 2 | 384 | 2900
*Compute* | *CPU*, *M* | 484 | 192 | -
*Compute* | *CPU*, *M-IO* | 48 | 192 | 1490
*Compute* | *CPU*, *M-FMI* | 240 | 192 | -
*Compute* | *CPU*, *L* | 92 | 384 | -
*Compute* | *CPU*, *L-IO* | 40 | 384 | 3600
*Compute* | *CPU*, *XL* | 12 | 768 | 1490
*Compute* | *CPU*, *BM* | 6 | 1500 | 5960
*Compute* | *GPU* | 80 | 384 | 3600

: \label{tab:puhti-nodes}
This table shows all nodes on the Puhti cluster by category and type.
For service nodes, the node type associates them with their function in the cluster.
For compute nodes, the node types associate them with the number of computing resources they have.
The node count tells us the number of nodes of the given node type.

The *Puhti* cluster has various *service nodes* and 1002 *compute nodes* as seen in Table \ref{tab:puhti-nodes}.
The services nodes consist of *utility nodes* for development and administration, *login nodes* for users to log in to the system, and MDS and OSS nodes for the Lustre file system.
The compute nodes consist of 922 *CPU nodes* and 80 *GPU nodes*.
Each login and compute node consists of two *Intel Xeon Gold 6230* CPUs with 20 cores and 2.1 GHz base frequency.
In addition to CPUs, each GPU node has four *Nvidia Volta V100* GPUs, and each GPU has 36 GiB of GPU memory.
We type nodes based on how much memory (RAM) and *fast local storage* they contain and whether they contain GPUs.
Fast local storage is a Solid State Disk (SSD) attached to the node via *Non-Volatile Memory Express (NVMe)* for processes to perform I/O intensive work instead of relying on the global storage from the Lustre file system.
[@docs-csc]

The global storage on Puhti consists of a Lustre parallel file system, introduced in Section \ref{lustre-parallel-file-system}, with two virtualized MDSs and eight virtualized OSSs with an SFA18KE controller.
At the time of writing, Puhti has Lustre version 2.12.6 from *DataDirect Networks (DDN)*.
Each MDS has two MDTs connected to 20 of 800 GB NVMe, and each OSS has three OSTs connected to 704 of 10 TB SAS HDD.
The total storage capacity of the file system is 4.8 PBs since part of the total capacity is reserved for redundancy.

The cluster connects nodes via a network with a fat-tree topology.
In the network, each node connects to all L1 switches, and each L1 switch connects to all L2 switches.
The connections use *Mellanox HDR InfiniBand* (100 Gb/s IB HDR100).
The network has a total of 28 L1 switches and 12 L2 switches.
Figure \ref{fig:puhti-network} shows a simplified, high-level overview of the network.

![
Rounded rectangles on the left illustrate compute, utility, and login nodes, whereas the dashed rectangles below are the optional attached local storage.
Rounded rectangles on the right illustrate the Lustre nodes, where the rectangles below are the appropriate Lustre targets.
The lines represent the network connections, and the circles represent the network switches.
Three dots between nodes or switches indicate that there are many of them.
\label{fig:puhti-network}
](figures/puhti-hardware.drawio.svg)

TODO: illustrate that there are multiple MDTs per MDS and OSTs per OSS in the figure


## System configuration
As mentioned in Section \ref{linux-operating-system}, most high-performance clusters use the Linux operating system.
Puhti also uses Linux, specifically the *RedHat Enterprise Linux Server* as its operating system.
The version transitioned from 7.9 to 8.6 during the thesis writing.
Each node in Puhti has a *hostname* in the form `<nodename>.bullx`.
The format of the *node name* string using Perl compatible regular expression syntax is **`puhti-[[:alnum:]_-]+`** for service nodes and **`r[0-9]{2}[c,m,g][0-9]{2}`** for compute nodes.
For example, `puhti-login12` or `r01c01`.
We can use node names to separate file system operations at a node-specific level.

In CSC systems, users have a *user account* which can belong to one or more *projects*.
We use projects for setting quotas and accounting for computational resources and storage.
We measure the usage of computational resources in *Billing Units (BU)*.
Resources, such as reserved CPU cores, memory, local disk, GPUs, and storage, use different rates of BUs.

Puhti associates each user account with a *user* and each project with a *group*.
We can use user IDs (UID) and group IDs (GID) as identifiers for measuring file system usage at the user or group level.
Puhti reserves UIDs from 0 to 999 for system processes, for example, 0 is the root, and 666 is job control.
It is helpful to separate the file system operations performed by system UIDs from the other UIDs.

Puhti separates its file system into *storage areas*, such that each storage area has a dedicated directory.
It shares a Lustre parallel file system across *home*, *projappl*, and *scratch* storage areas with different uses and quotas.

- *Home* is intended for storing personal data and configuration files.
In the file system, it resides at `/users/<user>` available via the `$HOME` variable and has a default quota of 10 GB and 100 000 files per user.

- *Projappl* is intended for storing project-specific application files such as compiled libraries.
It resides at `/projappl/<project>` and has a default quota of 50 GB and 100 000 files per project.

- *Scratch* is intended for short-term data storage in the cluster.
It resides at `/scratch/<project>` and has a default quota of 1 TB and 1 000 000 files per project.
Users should move files that require long-term storage to long-term data storage outside Puhti.

As a general guideline, jobs should use the *scratch* area for storing data.
They should access the *home* or *projappl* areas only to read or copy configuration or application-specific files at the beginning of the job.
We focus on monitoring the usage of the shared Lustre file system.

Puhti also has two local storage areas, *local scratch* and *tmp*.
They are intended for temporary file storage for I/O heavy operations to avoid burdening the Lustre file system.
Users who want to keep data from local storage after a job completion should copy it to scratch since the system regularly cleans the local storage areas.

- *Local scratch*, mounted on a local SSD, is indented for batch jobs to perform I/O heavy operations.
Its quota depends on how much the user requests for the job.
It resides at `/run/nvme/job_${SLURM_JOB_ID}/data` available via the `$LOCAL_SCRATCH` variable.

- *Tmp*, mounted on RAMDisk, is intended for login and interactive jobs to perform I/O heavy operations such as post and preprocessing data, compiling libraries, or compressing data.
It resides at `/local_scratch/<user>` available via the `$TMPDIR` variable.

In this work, we do not monitor the usage of the local storage areas.
In the future, we should include local storage in monitoring to understand how users use them and whether they use them as intended.


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
Each partition has a name associated with resource limits and a set of node types from Table \ref{tab:puhti-nodes}.
Typically, memory and local storage limits are the same for the node type.

Puhti uses the Slurm workload manager, introduced in Section \ref{slurm-workload-manager}.
At the time of writing, the version was 21.08.7, but it is updated regularly.
It has partitions with different resource limits, set by administrators, as seen in Table \ref{tab:slurm-partitions}.
When we submit a job to Slurm, we must specify which partition it will run, the project used for billing, and the resource we wish to reserve.
There are concrete examples of Slurm job scripts for Puhti in Appendix \ref{slurm-job-scripts}.
Slurm schedules the job to run when sufficient resources are available using a fair share algorithm.
It sets different job-specific environment variables for each job such that programs can access and use the job information within the process.
We can use the *Slurm Job Identifier* (`SLURM_JOB_ID` environment variable) as an identifier to collect job-specific file operations.
We have set Slurm to perform accounting of details about the submitted jobs to that we can combine them with file system usage data in the analysis.

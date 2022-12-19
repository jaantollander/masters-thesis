\newpage

# Puhti cluster at CSC
This section presents the configuration of the *Puhti* cluster, a Petascale system operated by CSC in Finland.
It has over five hundred monthly users and a diverse user base, which makes it interesting for studying file system usage.
Puhti is a Finnish noun that means having energy.
*CSC -- The IT Center for Science* is an organization that provides ICT services, including high-performance computing, cloud computing, data storage, computer networking, training, and technical support for higher education institutions, research institutes, culture, public administration, and enterprises in state of Finland [@about-csc].


## Hardware configuration

Node category | Node type | Node count | Memory \newline (GiB per node) | Local storage \newline (GiB per node)
-|-|-|-|-
*Lustre* | *MDS* | 2 |   |  
*Lustre* | *OSS* | 8 |   |  
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
All nodes on the Puhti cluster by category and type.
For service nodes, they node type associates them with their function in the cluster.
For compute nodes, the node types associate them with the amount of computing resources they have.
The node count tells us how many nodes there are of the given node type.

The *Puhti* cluster has various *service nodes* and 1002 *compute nodes* as seen on the Table \ref{tab:puhti-nodes}.
The services nodes consist of *utility nodes* for development and administration, *login nodes* for users to login to the system and MDS and OSS nodes for the Lustre file system.
The compute nodes consist of 922 *CPU nodes* and 80 *GPU nodes*.
Each login and compute node consists of two *Intel Xeon Gold 6230* CPUs with 20 cores and 2.1 GHz base frequency.
In addition to CPUs, each GPU node has four *Nvidia Volta V100* GPUs and each GPU has 36 GiB of GPU memory.
We give compute nodes types based on how much memory (RAM) and *fast local storage* they contain, and whether they contains GPUs.
Fast local storage is a Solid State Disk (SSD) attached to the node via *Non-Volatile Memory Express (NVMe)* to perform I/O intensive processes instead of having to rely on the global storage from the Lustre file system.
[@docs-csc]

The global storage on Puhti consists of a Lustre file system that has 2 MDSs and 8 virtualized OSSs with SFA18KE controller.
At the time of writing, Puhti has Lustre version 2.12.6 from *DataDirect Networks (DDN)*.
Each MDS has 2 MDTs connected to 20 $\times$ 800 GB NVMe and each OSS has 3 OSTs connected to 704 $\times$ 10 TB SAS HDD.
The total storage capacity of the file system is 4.8 PBs since part of the total capacity is reserved for redundancy.

Nodes are connected via a network with a fat-tree topology.
In the network, each node is connected to all L1 switches, and each L1 switch is connected to all L2 switches.
The connections use *Mellanox HDR InfiniBand* (100 GB/s IB HDR100).
The network has a total of 28 L1 switches and 12 L2 switches.
The Figure \ref{fig:puhti-network} shows a simplified, high-level overview of the network.

![
Rounded rectangles on the left illustrate compute, utility, and login nodes, whereas the dashed rectangles below are the optional attached local storage.
Rounded rectangles on the right illustrate the Lustre nodes, where the rectangles below are the appropriate Lustre targets.
The lines represent the network connections, and the circles represent the network switches.
Three dots between nodes or switches indicate that there are many of them.
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

In Puhti, each user account is associated with a *user* and each project with a *group*.
We can use user IDs (UID) and group IDs (GID) as identifiers for measuring file system usage in user or group level.
We should note that, UIDs from 0 to 999 to are reserved for system processes.
For example, 0 is root and 666 is job control.
It is useful to separate the file system operations performed by system UIDs from the other UIDS.

File system is separated to *storage areas*.
Each storage area has a dedicated directory.
The global, Lustre file system is shared across *home*, *projappl*, and *scratch* storage areas with different uses and quotas.

- *Home* is intended for storing personal data and configuration files.
In the file system, it resides at `/users/<user>` available via the `$HOME` variable and has a default quota of 10 GB and 100 000 files per user.

- *Projappl* is intended for storing project-specific application files such as compiled libraries.
It resides at `/projappl/<project>` and has a default quota of 50 GB and 100 000 files per project.

- *Scratch* is intended for short-term storage of data used in the cluster.
It resides at `/scratch/<project>` and has a default quota of 1 TB and 1 000 000 files per project.
Files that require long-term storage should be moved to a long-term data storage outside Puhti.

Jobs should use the *scratch* area for storing data.
They should access *home* or *projappl* areas only to read or copy configuration files or application specific files in the beginning of the job.

There are two local storage areas, *local scratch* and *tmp*, that are intended for temporary file storage for I/O heavy operations.
User should copy data that they wish to keep after the job has completed to *scratch* since files in these temporary storage areas are cleaned regularly.

- *Local scratch* is indented for batch jobs to perform I/O heavy operations.
It is mounted on local SSD.
The quota depends on how much is requested for the job.
It resides at `/run/nvme/job_<jobid>/data` available via the `$LOCAL_SCRATCH` variable.

- *Tmp* is intended for login and interactive jobs to perform I/O heavy operations such as post and preprocessing of data, compiling libraries, or compressing data.
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
Each partition has a name and is associated with resources limits and set of node types from Table \ref{tab:puhti-nodes}.
Typically, memory and local storage limits are the same as for the node type.

Puhti uses Slurm as a worload manager.
At the time of writing the version was 21.08.7, but it is updated regularly.
It has partitions with different resource limits as seen on Table \ref{tab:slurm-partitions}.
When we submit a job to Slurm, we must specify in which partition it will run, the project which used for billing, and the resource we wish to reserve.
Slurm schedules the job to run when sufficient resource are available using a fair share algorithm.
It sets different job specific environment variables for each job such that programs can access and use the job information within the process.
We can use the *Slurm Job Identifier* (`SLURM_JOB_ID` environment variable) as identifier to collect job specific file operations.
Slurm also performs accounting of other details about the submitted jobs.
See examples of Slurm job scripts in the Appendix \ref{slurm-job-scripts}.


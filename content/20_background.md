\newpage

# Background
- *What has been done previously?*
- *What do we know about the research topic beforehand?*
- *Balanced explanation of the whole research field.*

---

## High-performance computing
*High-performance computing (HPC)* is a practice of aggregating large amounts of computing resources to solve computationally intensive problems such as simulating complex systems and solving large computational models [@definition-hpc].
HPC is also applied for data science and training machine learning models.
Below we list some examples of commercial and research applications of HPC.

* Weather modeling for weather forecasting
* Climate modeling for understanding climate change
* Financial analytics for trading decisions
* Data analysis for oil and gas exploration
* Fluid simulation such as airflow for cars and airplanes
* Molecular dynamics simulation for pharmaceutical design
* Cosmological simulation for understanding galaxy creation

A defining characteristic of HPC is to utilize *parallelization* to aggregate computing resources.
HPC uses *parallel computing* to perform a large amount of processing simultaneously.
Contemporary processors employ multiple levels of parallelism, such as bit-level, instruction-level, data, and task parallelism.
HPC may also employ *parallel storage* to aggregate a large amount of storage memory.
Computer clusters are a common choice for HPC for parallelization.


## Computer cluster
*Computer cluster* is a system comprised of multiple connected computers that form a single, more powerful machine [@definition-computercluster].
Individual computers in the system are called *compute nodes*.
They consist of processors, memory, and optionally *fast local storage*.
A computer cluster is a homogenous system where each node performs the same task.
Nodes are connected via high-speed, local area *networks*.
Clusters also have *global storage* for storing data such as programs and results from the computation.

The components of computer clusters consist of commercially available consumer hardware.

Typically, a computer cluster is centrally managed by an organization such as a company or university.
It relies on administrators and software from the organization and various vendors to configure the machine, install software, orchestrate its services and maintain it.
The organization may offer access to the machine as a service with billing based on the usage of computer resources, such as the amount of time, memory, and processors requested.
A cluster may also be built for internal use in the organization.


## Linux operating system
At the time of writing, all high-performance computer clusters use the *Linux operating system* [@osfam].
The *Linux kernel* [@linuxkernel] is the core of the Linux operating system.
It derives from the original *UNIX operating system* and closely follows the *POSIX standard*. For a comprehensive overview of the features of the Linux kernel, we recommend and refer to *The Linux Programming Interface* book by Michael Kerrisk [@tlpi].

In this work, we will refer to the Linux kernel as the *kernel*.
The kernel is the central system that manages and allocates computer resources such as CPU, RAM, and devices.
It is responsible for tasks such as process scheduling, memory management, providing a file system, creating and termination of processes, access to devices, networking, and providing an application programming interface for system calls which makes the kernel services available to programs.
*System calls* enable user processes to request the kernel to perform certain actions for the process, such as file I/O, and provide separation between kernel space and user space.
Library functions, such as functions in the C standard library, implement caller friendly layer on top of system calls for performing system operations.

*Input/Output (I/O)* refers to the communication between a computer and the outside world, for example, a disk, display, or keyboard.
Linux implements a universal file I/O model, which means that it represents everything from data stored on disk to devices and processes as files.
It uses the same system calls for performing I/O on all types of files.
Consequently, the user can use the same file utilities to perform various tasks, such as reading and writing files or interacting with processes and devices.
The kernel only provides one file type, a sequential stream of bytes.
In this work, we focus on the storage file system I/O.

Linux is a *multiuser* system, which means that multiple users can use the computer at the same time.
The kernel provides an abstraction of a virtual private computer for each user, allowing multiple users to operate independently on the same computer system.
Linux systems have one special user, called the *super user* or *root user*, which has the privileges to access everything on the system.
The super user is used by *system administrators* for administrative tasks such as installing or removing software and system maintenance. [@tlpi, secs. 2-3]

A *Linux distribution* comprises some version of the Linux kernel combined with a set of utility programs such as a shell, command-line tools, a package manager, and a graphical user interface.


## File system interface
The kernel provides an abstraction layer called *Virtual File System (VFS)*, which defines a generic interface for file-system operations for concrete file systems such as *ext4*, *btrfs*, or *FAT*.
This allows programs to use different file systems in a uniform way using the operations defined by the interface.
The interface contains the file system-specific system calls.
We explain the most important system calls below.
For in-depth documentation about system calls, we refer to *The Linux man-pages project* [@linuxmanpages, sec. 2].
We denote system calls using the syntax `systemcall()`.

`mknod()`
: creates a new file.

`open()`
: opens a file and returns a file descriptor.
It may also create a new file by calling `mknod` if it doesn't exists.

`close()`
: closes a file descriptor which releases the resource from usage.

`read()`
: reads bytes from a file.

`write()`
: writes bytes to a file.

`link()`
: creates a new hard link to an existing file.
There can be multiple links to the same file.

`unlink()`
: removes a hard link to a file.
If the removed hard link is the last hard link to the file, the file is deleted, and the space is released for reuse.

`symlink()`
: create a symbolic (soft) link to a file.

`mkdir()`
: creates new directory.

`rmdir()`
: removes an empty directory.

`rename()`
: renames a file by moving it to new location.

`chown()`
: changes file ownership.

`chmod()`
: changed file permissions such as read, write, and execute permissions.

`stat()`
: return file information.

`statfs()`
: returns file system information.

`sync()`
: commits file system caches to disk.

`fallocate()`
: manipulates file space.

`quotactl()`
: manipulates disk quotas.


## Example: File I/O with system calls
An example, written in the C programming language, demonstrating `open`, `close`, `read`, and `write` system calls with the flags `O_RDONLY`, `O_CREAT`, `O_WRONLY`, and modes `S_IRUSR` and `S_IWUSR`.
The example program opens `input.txt` in read only mode, reads at most `size` bytes to a buffer and then creates and writes them into `output.txt` file in write only mode.
Note that this example does not do any error handling that should be done in a proper program.

---

```c
#include<fcntl.h>
#include<sys/types.h>
#include<unistd.h>
#include<sys/stat.h>

int main()
{
    int n;  // number of bytes read
    int fd1, fd2;  // file descriptors
    const int size = 4096;  // buffer size
    char buffer[size];  // reserve memory for reading bytes
    // Read input file
    fd1 = open("input.txt", O_RDONLY);
    n = read(fd1, buffer, size);
    close(fd1);
    // Write output file
    fd2 = open("output.txt", O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR);
    write(fd2, buffer, n);
    close(fd2);
}
```

---

The following example writes `hello hole world` to a `output.txt` file.
It then deallocate bytes from 5 to 10 such that the file keeps its original size using `fallocate` with mode `FALLOC_FL_PUNCH_HOLE` and `FALLOC_FL_KEEP_HOLE`.
This operation is refered to as *punching* a hole to file.

---

```c
#define _GNU_SOURCE
#include<fcntl.h>
#include<sys/types.h>
#include<unistd.h>
#include<sys/stat.h>

int main()
{
    int fd;  // file descriptor
    fd = open("output.txt", O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR);
    write(fd, "hello hole world", 16);
    fallocate(fd, FALLOC_FL_PUNCH_HOLE|FALLOC_FL_KEEP_SIZE, 5, 5);
    close(fd);
}
```

---


## Client-server architecture
A *client-server application* is an application that is broken into two processes, a client and a server.
The *client* requests a server to perform some service by sending a message.
The *server* examines the client's message, performs the appropriate actions, and sends a response message back to the client.
The client and server may reside in the same host computer or separate host computers connected by a network.
They communicate with each other by some Interprocess Communication (IPC) mechanism.
"Typically, the client application interacts with a user, while the server application provides access to some shared resource. Commonly, there are multiple instances of client processes communicating with one or a few instances of the server process." [@tlpi, sec. 2]


## Lustre cluster storage system
Lustre provides storage architecture for Linux clusters [@lustredocs, secs. 1-2].
The *Lustre file system* provides a POSIX standard-compliant file system interface.
It aggregates storage such that all files are available on the entire cluster, not only on specific nodes.

The Lustre file system is designed using the client-server architecture.
*Lustre Clients* on a computer cluster are compute nodes running the Lustre client software and have the Lustre file system mounted.
The Lustre client software provides an interface between the Linux virtual file system and the Lustre servers.
For Lustre clients, the file system appears as a single, coherent, synchronized namespace across the whole cluster.

Lustre file system separates file metadata and data operations and handles them using dedicated servers.
Each server is connected to one or more storage units called targets.

*Metadata Servers (MDS)* provide access to file metadata and handle metadata operations for Lustre clients.
The metadata, such as filenames, directories, permissions, and file layout, is stored on *Metadata Targets (MDT)*, which are storage units attached to an MDS.

*Object Storage Servers (OSS)* provide access to and handle file data operations for Lustre clients.
The file data is stored in one or more objects, each object on a separate *Object Storage Target (OST)*, which is a storage unit attached to an OSS.

*Management Server (MGS)* stores configuration information for the Lustre file system and provides it to the other components.

Lustre file system components are connected using *Lustre Networking (LNet)*, a custom networking API that handles metadata and file I/O data for the Lustre file system servers and clients.
LNet supports many network types, including InfiniBand and IP networks, with simultaneous availability between them.


## Batch processing
Many clusters use a *workload manager* to run programs as *batch processes*.
A batch process is a computation that runs from start to finish without user interaction, unlike interactive processes such as word editors or web servers which respond to user input.
Furthermore, batch processes on clusters must predefine their resource requirements.


## Slurm workload manager
*Slurm* is a workload manager for Linux clusters.
It is responsible for allocating access to the computing resources for users to perform batch processes.
These computing resources include nodes, processors-per-node, memory-per-node, and maximum duration.
The access to the resources may be exclusive or nonexclusive, depending on the configuration.
We refer to such a resource allocation as a *job*.
An individual job may contain multiple *job steps* that may execute sequentially or in parallel.
Slurm provides a framework for starting, executing, and monitoring work on the allocated nodes.
Slurm groups nodes into *partitions*, which may be overlapping.
It also maintains a queue of jobs waiting for resources to become available for them to be started.
Slurm can also perform accounting for resource usage.
[@slurmdocs]


## Example: Puhti cluster
The *Puhti* cluster [@csccomputing] has two *login nodes* and 762 *compute nodes*.
The compute nodes consist of 682 *CPU nodes* and 80 *GPU nodes*.
Each compute node has 2 *Intel Xeon Gold 6230* CPUs.
Each CPU has 20 cores and 2.1 GHz base frequency.
Compute nodes have a varying amount of memory (RAM) described below.
Additionally, each GPU node has 4 *Nvidia Volta V100* GPUs with 36 GiB of memory each.
Some of the nodes have *fast local storage*, that is, a local Solid State Disk (SSD), to support I/O intensive processes.
Compute nodes are divided into *node types* with different amounts of nodes, memory and fast local storage as below.

**M** type
: has 484 nodes and 192 GiB of memory.

**M-IO** type
: has 48 nodes, 192 GiB of memory, and 1490 GiB of fast local storage.

**L** type
: has 92 nodes and 384 GiB of memory.

**L-IO** type
: has 40 nodes, 384 GiB of memory, and 3600 GiB of fast local storage.

**XL** type
: has 12 nodes, 768 GiB of memory, and 1490 GiB of fast local storage.

**BM-IO** type
: has 6 nodes, 1.5 TiB of memory, and 1490 GiB of fast local storage.

**GPU** type
: has 80 nodes, 384 GiB of memory, and 3600 GiB of fast local storage.

The nodes are connected using *Mellanox HDR InfiniBand*.

---

At the time of writing, Puhti is using the *RedHat Enterprise Linux Server 7.9* distribution.

```
$ cat /etc/redhat-release
Red Hat Enterprise Linux Server release 7.9 (Maipo)
```

---

The global storage on Puhti consist of Lustre file system that has 2 MDSs with 2 MDTs on each server and 8 OSSs with 3 OSTs on each server.
The file system is shared across *home*, *project*, and *scratch* storage areas.

```
$ lctl --version
2.12.6_ddn72
```

---

Slurm partitions with different resources limits ...

The Slurm version is

```
$ sinfo --version
slurm 21.08.7-1_issue_803
```


## Example: Slurm job on Puhti
We can submit a job to the Slurm scheduler as a shell script via the `sbatch` command.
We can specify the options as command line arguments as we invoke the command or in the script as comments.
The script specifies job steps using the `srun` command.

---

```sh
#!/usr/bin/env bash
#SBATCH --job-name=<job-name>
#SBATCH --account=<project>
#SBATCH --partition=large
#SBATCH --time=02:00:00
#SBATCH --nodes=2
#SBATCH --tasks-per-node=2
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=1G
#
# 1. job step
srun <program-1>
# 2. job step
srun --nodes 1 --ntasks 2 <program-2> &
# 3. job step
srun --nodes 1 --ntasks 2 <program-3> &
# Wait for job 2. and 3. to complete
wait
```

---

In the above example, the first program will run on the first job step utilizing all given nodes, tasks, and cpus and the majority of the given time.
The program is some large parallel program such as a large, well parallelizing simulation.

The second and third programs job steps will run in parallel after the first step, both utilizing all tasks and cpus from a single node.
These programs could be, for example, programs for post processing steps, for example, processing and backing up the simulation results.


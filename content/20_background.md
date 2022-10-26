\newpage

# Background
- *What has been done previously?*
- *What do we know about the research topic beforehand?*
- *Balanced explanation of the whole research field.*

---

## High-performance computing
We can thing about *computing* as applying rules on a string of symbols to transform it for some goal-oriented task such as solving a mathematical problem.
At each *unit of time*, we apply the rules onto the string in a way defined by the chosen *model of computation*. 
For example, first applicable rule at a time or all applicable rules at once.
Both, the set of rules and set of symbols must be discrete.
A *computation* is the process of applying the rules until we can no longer apply any rules, that is, the process halts.
The *memory* requirement of a computation is the maximum size of the string during the computation.
We can visualize the progression of a computation as a directed, acyclic graph where each string of symbols, known as a state, is a node and transformation from one state to another is an edge.

Real-world computers derive from these concepts.

- symbols are bits typically read in bytes (8 bits)
- rules are intructions to the processor
- memory is hierarchical, and divided into working and storage memories

---

- *What is and why do we need high-performance computing?*
- *What are the defining characteristics of high-performance computing (HPC)?*
- *How does HPC related to computer clusters?*

*Serial computing* refers to performing one operation at a time.
In contrast, *parallel computing* is about performing multiple independent operations simultaneously, with the goal of reducing run time, performing larger calculations, and decreasing energy consumption.

*High-performance computing (HPC)* relies on parallel computing to provide large amount of computing resources for solving computationally intensive problems.
These problems include simulating complex systems, solving large computational models, data science and training machine learning models.
Examples of commercial and research applications of HPC include [@definition-hpc]:

- Weather modeling for weather forecasting
- Climate modeling for understanding climate change
- Financial analytics for trading decisions
- Data analysis for oil and gas exploration
- Fluid simulation such as airflow for cars and airplanes
- Molecular dynamics simulation for pharmaceutical design
- Cosmological simulation for understanding galaxy creation

The performance of HPC system is traditionally measured in operations per unit of time.
However, the role of data is becoming increasingly important with data science and machine learning.

---

A *computer* consists of processor and memory.
We can link multiple computers together to form a computer network.

Parallelism in practice exist in multiple, hierarchical levels.
[@parallel-and-high-performance-computing]

- Process-based parallelization, communication between processes using message passing in distributed memory
- Thread-based parallelization, communication between threads using shared data via memory
- Vectorization to perform multiple operations with one instruction
- Stream processing through specialized processors

HPC may also employ *parallel storage* to aggregate a large amount of storage memory.

---

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
The *Linux kernel* [@linuxkernel] is the core of the Linux operating system
It derives from the original *UNIX operating system* and closely follows the *POSIX standard*.
Linux kernel is written in the *C programming language*.
For a comprehensive overview of the features of the Linux kernel, we recommend and refer to *The Linux Programming Interface* book by Michael Kerrisk [@tlpi].


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


## Linux file system interface
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

Next, we present two examples of performing file I/O using system calls.
Please note that these examples do not perform any error handling that should be done by proper programs.

The first example program demonstrates opening and closing file descriptors, reading bytes from a file and writing bytes to a file.
It opens `input.txt` in read only mode, reads at most `size` bytes to a buffer and then creates and writes them into `output.txt` file in write only mode.
The code performs the `open`, `close`, `read`, and `write` system calls with the flags `O_RDONLY`, `O_CREAT`, `O_WRONLY`, and modes `S_IRUSR` and `S_IWUSR`.

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

The second example demonstrates a less common feature of "punching a hole" to a file, creating a sparse file.
The hole appears as null bytes when reading the file, without takeing any space on the disk.
This feature supported by certain Linux file systems such as ext4.
The following code writes `hello hole world` to a `output.txt` file.
It then deallocate bytes from 5 to 10 such that the file keeps its original size using `fallocate` with mode `FALLOC_FL_PUNCH_HOLE` and `FALLOC_FL_KEEP_HOLE`.

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


## Lustre cluster storage system
Lustre provides storage architecture for Linux clusters [@lustre-storage-architecture; @lustredocs, secs. 1-2].
The *Lustre file system* provides a POSIX standard-compliant file system interface.
It aggregates storage such that all files are available on the entire cluster, not only on specific nodes.
The Lustre file system is designed using the client-server architecture.

A *client-server application* is an application that is broken into two processes, a client and a server.
The *client* requests a server to perform some service by sending a message.
The *server* examines the client's message, performs the appropriate actions, and sends a response message back to the client.
The client and server may reside in the same host computer or separate host computers connected by a network.
They communicate with each other by some Interprocess Communication (IPC) mechanism.
"Typically, the client application interacts with a user, while the server application provides access to some shared resource. Commonly, there are multiple instances of client processes communicating with one or a few instances of the server process." [@tlpi, sec. 2]

*Lustre Clients* on a computer cluster are nodes running the Lustre client software and have the Lustre file system mounted.
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


## Slurm workload manager
Typically, clusters rely on a *workload manager* for allocating access to computing resources, scheduling and running programs which may instantiate an interactive or a batch process.
A batch process is a computation that runs from start to finish without user interaction compared to an interactive processes such as an active terminal, a word editor or a web server which respond to user input.
We must specify limits for the resources we request.

*Slurm* is a workload manager for Linux clusters [@slurmdocs].
These computing resources include nodes, cores, memory, and time.
The access to the resources may be exclusive or nonexclusive, depending on the configuration.
We refer to such a resource allocation as a *job* in a job script.
An individual job may contain multiple *job steps* that may execute sequentially or in parallel.
Slurm provides a framework for starting, executing, and monitoring work on the allocated nodes.
Slurm groups nodes into *partitions*, which may be overlapping.
It also maintains a queue of jobs waiting for resources to become available for them to be started.
Slurm can also perform accounting for resource usage.


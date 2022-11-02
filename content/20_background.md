\newpage

# Background
- *What has been done previously?*
- *What do we know about the research topic beforehand?*
- *Balanced explanation of the whole research field.*

---

## High-performance computing
- *What is and why do we need high-performance computing?*
- *What are the defining characteristics of high-performance computing (HPC)?*
- *How does HPC related to computer clusters?*
- Good references are needed in this section

---

Fundamentally, we can think about *computing* as applying *rules* on a string of symbols to transform it for some goal-oriented task such as solving a mathematical problem.
At each *unit of time*, we apply the rules onto the string in a way defined by the chosen *model of computation*. 
For example, first applicable rule at a time or multiple rules at once.
Both, the set of rules and set of symbols must be discrete.
*Computation* is the process of applying the rules until we can no longer apply any rules and the process halts.
The *memory* requirement of a computation is the maximum size of the string during the computation.
Some models of computation are only theoretical tools while others we can implement in the real world using physical processes.

Contemporary computers represent data in digital form, typically as binary digits using symbols 0 and 1 referred as *bits*.
Multiple bits in a row form a binary string and a binary string of 8 bits is called a *byte*.
Rules correspond to intructions to a computer processor that manipulate bytes, for example adding two 32-bit integers together represented by 4 bytes.
Memory is consists of multiple levels volatile *working* memory and non-volatile *storage* memory organized in hierarchical way based on factors such as proximity to the processor, access speed, and cost.
Models of computation include serial and parallel computing.
*Serial computing* refers to performing one operation at a time.
In contrast, *parallel computing* is about performing multiple independent operations simultaneously, with the goal of reducing run time, performing larger calculations, and decreasing energy consumption.

*High-performance computing (HPC)* relies on parallel computing to provide large amount of computing resources for solving computationally demanding and data intensive problems.
These problems include simulating complex systems, solving large computational models, data science and training machine learning models.
Examples of commercial and research applications of HPC include:

- Weather modeling for weather forecasting
- Climate modeling for understanding climate change
- Financial analytics for trading decisions
- Data analysis for oil and gas exploration
- Fluid simulation such as airflow for cars and airplanes
- Molecular dynamics simulation for pharmaceutical design
- Cosmological simulation for understanding galaxy creation

We can connect multiple computers together to form a computer network.
We refer to the individual computers in the network as *nodes*.
Most *HPC systems* are computer clusters.
*Computer cluster* is a computer network that uses high-speed fiber optic cables between network switches to connect large amounts of homogenous nodes to form a more powerful system.
It usually has a large amount of storage memory as well.
Computer clusters are usually centrally managed by an organization such as a company or university.
They rely on administrators and software from the organization and various vendors to configure the machine, install software, orchestrate their services and maintain them.
The organizations may offer access to the machine as a service with billing based on the usage of computer resources, such as the amount of time, memory, and processors requested.
A cluster may also be built for internal use in the organization.

The performance of HPC system is traditionally measured in standard linear algebra operations per second and focused on processor and working memory.
However, the storage is becoming increasingly important with data science and machine learning which require huge amounts of data that must be transported between storage and working memory.
This is also an important reason for studying storage in HPC systems.


## Linux operating system
An *operating system (OS)* is software that manages computer resources and provides common services for application programs via an *application programming interface (API)*.
At the time of writing, all high-performance computer clusters use the *Linux operating system* [@osfam].
The *Linux kernel* [@linuxkernel] is the core of the Linux operating system and is written in the *C programming language*.
It derives from the original *UNIX operating system* and closely follows the *POSIX standard*.
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
System call | Explanation
:-|:-------
`mknod` | Creates a new file.
`open` | Opens a file and returns a file descriptor. It may also create a new file by calling `mknod` if it doesn't exists.
`close` | Closes a file descriptor which releases the resource from usage.
`read` | Reads bytes from a file.
`write` | Writes bytes to a file.
`link` | Creates a new hard link to an existing file. There can be multiple links to the same file.
`unlink` | Removes a hard link to a file. If the removed hard link is the last hard link to the file, the file is deleted, and the space is released for reuse.
`symlink` | Create a symbolic (soft) link to a file.
`mkdir` | Creates new directory.
`rmdir` | Removes an empty directory.
`rename` | Renames a file by moving it to new location.
`chown` | Change file ownership.
`chmod` | Change file permissions such as read, write, and execute permissions.
`utime` | Change file timestamps
`stat` | Return file information.
`statfs` | Returns file system information.
`sync` | Commits file system caches to disk.
`fallocate` | Manipulates file space.
`quotactl` | Manipulates disk quotas.
`setxattr` | Set an extended attribute value
`getxattr` | Retrieve an extended attribute value

: \label{tab:systemcalls} Linux systemcalls (and their variants) for file system

The kernel provides an abstraction layer called *Virtual File System (VFS)*, which defines a generic interface for file-system operations for concrete file systems such as *ext4*, *btrfs*, or *FAT*.
This allows programs to use different file systems in a uniform way using the operations defined by the interface.
The interface contains the file system-specific system calls.
We explain the most important system calls below.
For in-depth documentation about system calls, we refer to *The Linux man-pages project* [@linuxmanpages, sec. 2].
In Linux, you can use `man 2 <systemcall>` command to read the manual page of an system call.
We present and explain the common system calls for the file system interface in the table \ref{tab:systemcalls}.

Next, we present two examples of performing file I/O using system calls.
Please note that these examples do not perform any error handling that should be done by proper programs.

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

The first example program demonstrates opening and closing file descriptors, reading bytes from a file and writing bytes to a file.
It opens `input.txt` in read only mode, reads at most `size` bytes to a buffer and then creates and writes them into `output.txt` file in write only mode.
The code performs the `open`, `close`, `read`, and `write` system calls with the flags `O_RDONLY`, `O_CREAT`, `O_WRONLY`, and modes `S_IRUSR` and `S_IWUSR`.

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

The second example demonstrates a less common feature of "punching a hole" to a file, creating a sparse file.
The hole appears as null bytes when reading the file, without takeing any space on the disk.
This feature supported by certain Linux file systems such as ext4.
The following code writes `hello hole world` to a `output.txt` file.
It then deallocate bytes from 5 to 10 such that the file keeps its original size using `fallocate` with mode `FALLOC_FL_PUNCH_HOLE` and `FALLOC_FL_KEEP_HOLE`.


## Lustre parallel file system
Parallel file system is a file system designed for clusters.
It stores data on multiple networked servers to facilitate high performance access and makes the data available via global namespace such that users do not need to know the physical location of the data blocks to access a file.
*Lustre* is a parallel file system which provides a POSIX standard-compliant file system interface for Linux clusters.
The Lustre file system is designed using the client-server architecture.
[@lustre-storage-architecture; @lustredocs, secs. 1-2]

A *client-server application* is an application that is broken into two processes, a client and a server.
The *client* requests a server to perform some service by sending a message.
The *server* examines the client's message, performs the appropriate actions, and sends a response message back to the client.
The client and server may reside in the same host computer or separate host computers connected by a network.
They communicate with each other by some Interprocess Communication (IPC) mechanism.

"Typically, the client application interacts with a user, while the server application provides access to some shared resource. Commonly, there are multiple instances of client processes communicating with one or a few instances of the server process." [@tlpi, sec. 2]

Nodes running the Lustre client software are known as *Lustre Clients*
The Lustre client software provides an interface between the Linux virtual file system and *Lustre servers*.
For Lustre clients, the file system appears as a single, coherent, synchronized namespace across the whole cluster.
Lustre file system separates file metadata and data operations and handles them using dedicated Lustre servers.
Each server is connected to one or more storage units called *Lustre targets*.

*Metadata Servers (MDS)* provide access to file metadata and handle metadata operations for Lustre clients.
The metadata, such as filenames, directories, permissions, and file layout, is stored on *Metadata Targets (MDT)*, which are storage units attached to an MDS.
On the other hand, *Object Storage Servers (OSS)* provide access to and handle file data operations for Lustre clients.
The file data is stored in one or more objects, each object on a separate *Object Storage Target (OST)*, which is a storage unit attached to an OSS.
Finally, the *Management Server (MGS)* stores configuration information for the Lustre file system and provides it to the other components.
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


## Computing at CSC
*CSC - The IT Center for Science* provides ICT services for higher education institutions, research institutes, culture, public administration and enterprises.
It is owned by the Finnish-state and higher education institutions.
These services include access to high-performance computing, cloud computing and data storage, as well as, training and technical support for using them.
We will be looking at the structure of CSC *Puhti* cluster.


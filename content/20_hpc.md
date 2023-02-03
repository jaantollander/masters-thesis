\clearpage

# High-performance computing
Fundamentally, computing is about repeatedly applying a logical rule on a string of symbols to transform it for some goal-oriented task, such as solving a mathematical problem.
In practice, we use computers for computing, which they do by leveraging physical processes.
Contemporary computers represent data in digital form as binary digits called *bits*.
Rules correspond to instructions to a computer processor that manipulates a string of bits in memory.
Memory consists of multiple levels of volatile *main memory* and non-volatile *storage* organized hierarchically based on factors such as proximity to the processor, access speed, and cost.
Models of computation include serial and parallel computing.
Serial computing refers to performing one operation at a time.
In contrast, parallel computing is about performing multiple independent operations simultaneously, intending to reduce run time, and performing larger calculations.

*High-performance computing (HPC)* relies on parallel computing to provide large computing resources for solving computationally demanding and data-intensive problems.
These problems include simulating complex systems, solving large computational models, data science, and training machine learning models.
Examples of commercial and research applications of HPC include:

- Weather modeling for weather forecasting
- Climate modeling for understanding climate change
- Financial analytics for trading decisions
- Data analysis for oil and gas exploration
- Fluid simulation, such as airflow for cars and airplanes
- Molecular dynamics simulation for pharmaceutical design
- Cosmological simulation for understanding galaxy creation
- Biosciences such as next-generation sequencing for studying genomes

Most *HPC systems* are computer clusters.
*Computer cluster* connects multiple computers, called *nodes*, via a high-speed network to form a more powerful system.
It usually has a large amount of storage as well.
Computer clusters are usually centrally managed by organizations such as companies or universities.
They rely on administrators and software from the organization and various vendors to configure the machine, install software, orchestrate their services, and maintain them.
The organizations may offer access to the machine as a service with billing based on the usage of computer resources, such as the amount of time, memory, processors, and storage requested.
Organizations may also build clusters for internal use.


## Linux operating system
An operating system (OS) is software that manages computer resources and provides standard services for application programs via an application programming interface (API).
<!-- TODO: (optional) explain Application binary interface (ABI) -->
At the time of writing, practically all high-performance computer clusters use the *Linux* operating system [@osfam].
Linux derives from the family of UNIX operating systems and closely follows the POSIX standard.

The *Linux kernel* [@linux-kernel-source] is the core of the Linux operating system, written in the C programming language.
The kernel is the central system that manages and allocates computer resources such as processors, memory, and other devices.
Its responsibilities include process scheduling, memory management, providing a file system, creating and terminating processes, access to devices, networking, and providing an application programming interface for system calls, making the kernel services available to programs.
*System calls* enable user processes to request the kernel to perform specific actions for the process, such as manipulating files.
They also provide separation between kernel space and user space.
Library functions, such as functions in the C standard library, implement a caller-friendly layer on top of system calls for performing system operations. [@tlpi]

Linux implements a *universal file I/O model*, which means that it represents everything from data stored on disk to devices and processes as files.
It uses the same system calls for performing I/O on all types of files.
Consequently, users can use the same file utilities to perform various tasks, such as reading and writing files or interacting with processes and devices.
The kernel only provides one file type, a sequential stream of bytes.

The kernel provides an abstraction layer called *Virtual File System (VFS)*, which defines a generic interface for file-system operations for concrete file systems such as ext4, Btrfs, or FAT.
VFS allows programs to use different file systems uniformly using the operations defined by the interface.
The interface contains the system calls such as `open()`, `close()`, `read()`, `write()`, `mknod()`, `unlink()` and others.
For in-depth documentation about system calls, we recommend the Linux Man Pages [@man-pages, sec. 2].
We demonstrate the relationship between different system calls with code examples in Appendix \ref{file-system-interface}.

Linux is a *multiuser* system, which means that multiple users can use the computer at the same time.
The kernel provides an abstraction of a virtual private computer for each user, allowing multiple users to operate independently on the same computer system.
Linux systems have one special user, called the *super user* or *root*, which can access everything on the system.
*System administrators* can use the super user for administrative tasks and system maintenance.

A *Linux distribution* comprises some version of the Linux kernel combined with a set of utility programs such as a shell, command-line tools, a package manager, and, optionally, a graphical user interface.


## Client-server application
A *client-server application* is an application that consists of two processes, a client and a server.
The *client* requests a server to perform some service by sending a message.
The *server* listens for the client's messages, examines them, performs the appropriate actions, and sends a response message back to the client.
The client and server may reside in the same or separate host computers connected by a network.
They communicate with each other by some Interprocess Communication (IPC) mechanism.
Usually, the client application interacts with a user, while the server application provides access to a shared resource.
Commonly, there are multiple instances of client processes communicating with one or a few instances of the server process.


## Lustre parallel file system
A parallel file system is a file system designed for clusters.
It stores data on multiple networked servers to facilitate high-performance access.
It makes the data available via a global namespace such that users do not need to know the physical location of the data blocks to access a file.
*Lustre* is a parallel file system that provides a POSIX standard-compliant file system interface for Linux clusters.
The Lustre file system is implemented as a set of *kernel modules* designed using the client-server architecture.
A kernel module is a software that extends the kernel, in this case, to provide a new file system.
[@lustre-storage-architecture; @docs-lustre, secs. 1-2]

Nodes running the Lustre client software are known as *Lustre Clients*.
The Lustre client software interfaces the virtual file system with *Lustre servers*.
For Lustre clients, the file system appears as a single, coherent, synchronized namespace across the whole cluster.
Lustre file system separates file metadata and data operations and handles them using dedicated Lustre servers.
Each Lustre server connects to one or more storage units called *Lustre targets*.

*Metadata Servers (MDS)* provide access to file metadata and handle metadata operations for Lustre clients.
Lustre stores the metadata, such as filenames, permissions, and file layout, on one or more storage units attached to an MDS, called *Metadata Targets (MDT)*.
On the other hand, *Object Storage Servers (OSS)* provide access to and handle file data operations for Lustre clients.
Lustre breaks file data into one or more objects; it stores each object on one or more storage units attached to an OSS, called *Object Storage Targets (OST)*.
Finally, the *Management Server (MGS)* stores configuration information for the Lustre file system and provides it to the other components.
Lustre file system components are connected using *Lustre Networking (LNet)*, a custom networking API that handles metadata and file I/O data for the Lustre file system servers and clients.
LNet supports many network types, including high-speed networks used in HPC clusters.
Lustre has a feature called *Lustre Jobstats* for collecting file system operations statistics from a Lustre file system.
We discuss how we use Jobstats in Section \ref{monitoring-system}.


## Slurm workload manager
Typically, the nodes on a cluster are separated into *front end* and *back end*.
The front end consists of login and utility nodes, and the back end consists of compute nodes.
Clusters rely on a *workload manager* to allocate access to computing resources, schedule, and run programs on the back end.
The programs may instantiate an interactive or batch process.
A batch process is a computation that runs from start to finish without user interaction compared to interactive processes such as an active terminal prompt or a text editor which respond to user input.

*Slurm* is a workload manager for Linux clusters [@slurm; @docs-slurm].
Unlike Lustre, Slurm operates in the user space, not kernel space.
Slurm provides a framework for starting, executing, and monitoring work on the allocated nodes with requested computing resources such as nodes, cores, memory, and time.
Resource access may be exclusive or nonexclusive, depending on the configuration.
Slurm maintains a queue of jobs waiting for resources to become available and can perform accounting for resource usage.
We refer to a resource allocation as a *job* and a job may contain multiple *job steps* that may execute sequentially or in parallel.
Administrators can group nodes into Slurm *partitions* on which they can set different policies such as queuing policies and maximum resource allocations.
A node may belong to more than one partition.
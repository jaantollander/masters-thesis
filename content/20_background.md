\newpage

# High-performance computing
## Overview
Fundamentally, we can think about *computing* as applying *rules* on a string of symbols to transform it for some goal-oriented task such as solving a mathematical problem.
At each *unit of time*, we apply the rules onto the string in a way defined by the chosen *model of computation*. 
For example, first applicable rule at a time or multiple rules at once.
Both, the set of rules and set of symbols must be discrete.
*Computation* is the process of applying the rules until we can no longer apply any rules and the process halts.
The *memory* requirement of a computation is the maximum size of the string during the computation.
Some models of computation are only theoretical tools while others we can implement in the real world using physical processes.

Contemporary computers represent data in digital form, typically as binary digits called *bits*.
Multiple bits in a row form a *binary string*.
Rules correspond to intructions to a computer processor that manipulate binary strings.
Memory consists of multiple levels volatile *working* memory and non-volatile *storage* memory organized in hierarchical way based on factors such as proximity to the processor, access speed, and cost.
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
- Bio sciences such as next generation sequencing for studying genomes

We can connect multiple computers together to form a computer network.
We refer to the individual computers in the network as *nodes*.
Most *HPC systems* are computer clusters.
*Computer cluster* is a computer network that uses high-speed network to connect large amounts of homogenous nodes to form a more powerful system.
It usually has a large amount of storage as well.
Computer clusters are usually centrally managed by an organization such as a company or university.
They rely on administrators and software from the organization and various vendors to configure the machine, install software, orchestrate their services and maintain them.
The organizations may offer access to the machine as a service with billing based on the usage of computer resources, such as the amount of time, memory, and processors requested.
A cluster may also be built for internal use in the organization.


## Linux operating system
An *operating system (OS)* is software that manages computer resources and provides common services for application programs via an *application programming interface (API)*.
At the time of writing, practically all high-performance computer clusters use the *Linux operating system* [@osfam].
The *Linux kernel* [@linux-kernel-source] is the core of the Linux operating system and is written in the *C programming language*.
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

The kernel provides an abstraction layer called *Virtual File System (VFS)*, which defines a generic interface for file-system operations for concrete file systems such as *ext4*, *btrfs*, or *FAT*.
This allows programs to use different file systems in a uniform way using the operations defined by the interface.
The interface contains the file system-specific system calls such as `open()`, `close()`, `read()`, `write()`, `mknod()`, `unlink()` and others.
For in-depth documentation about system calls, we recommend the Linux Man Pages [@man-pages, sec. 2]
We have listed some of the common system calls for the file system interface in the Appendix \ref{file-system-interface} and programming examples in Appendix \ref{programming-with-system-calls}.

Linux is a *multiuser* system, which means that multiple users can use the computer at the same time.
The kernel provides an abstraction of a virtual private computer for each user, allowing multiple users to operate independently on the same computer system.
Linux systems have one special user, called the *super user* or *root user*, which has the privileges to access everything on the system.
The super user is used by *system administrators* for administrative tasks such as installing or removing software and system maintenance.

A *Linux distribution* comprises some version of the Linux kernel combined with a set of utility programs such as a shell, command-line tools, a package manager, and optionally a graphical user interface.


## Client-server application
A *client-server application* is an application that is broken into two processes, a client and a server.
The *client* requests a server to perform some service by sending a message.
The *server* examines the client's message, performs the appropriate actions, and sends a response message back to the client.
The client and server may reside in the same host computer or separate host computers connected by a network.
They communicate with each other by some Interprocess Communication (IPC) mechanism.
Usually, the client application interacts with a user, while the server application provides access to a shared resource.
Commonly, there are multiple instances of client processes communicating with one or a few instances of the server process.


## Lustre parallel file system
Parallel file system is a file system designed for clusters.
It stores data on multiple networked servers to facilitate high performance access and makes the data available via global namespace such that users do not need to know the physical location of the data blocks to access a file.
*Lustre* is a parallel file system which provides a POSIX standard-compliant file system interface for Linux clusters.
The Lustre file system is a *kernel module* designed using the client-server architecture.
Kernel module is a software that extends the kernel, in this case, to provide a new file system.
[@lustre-storage-architecture; @docs-lustre, secs. 1-2]

Nodes running the Lustre client software are known as *Lustre Clients*
The Lustre client software provides an interface between the Linux virtual file system and *Lustre servers*.
For Lustre clients, the file system appears as a single, coherent, synchronized namespace across the whole cluster.
Lustre file system separates file metadata and data operations and handles them using dedicated Lustre servers.
Each server is connected to one or more storage units called *Lustre targets*.

*Metadata Servers (MDS)* provide access to file metadata and handle metadata operations for Lustre clients.
The metadata, such as filenames, permissions, and file layout, is stored on *Metadata Targets (MDT)*, which are storage units attached to an MDS.
On the other hand, *Object Storage Servers (OSS)* provide access to and handle file data operations for Lustre clients.
The file data is stored in one or more objects, each object on a separate *Object Storage Target (OST)*, which is a storage unit attached to an OSS.
Finally, the *Management Server (MGS)* stores configuration information for the Lustre file system and provides it to the other components.
Lustre file system components are connected using *Lustre Networking (LNet)*, a custom networking API that handles metadata and file I/O data for the Lustre file system servers and clients.
LNet supports many network types, including high-speed networks used in HPC clusters.


## Slurm workload manager
Typically, the nodes on a cluster are separated to *frontend* and *backend*.
Frontend consist of login and utility nodes and backend consists of compute nodes.
Clusters rely on a *workload manager* for allocating access to the computing resources, scheduling and running programs on the backend.
The programs may instantiate an interactive or a batch process.
A batch process is a computation that runs from start to finish without user interaction compared to an interactive processes such as an active terminal prompt or a text editor which respond to user input.
We must specify the resources we request and limits for them.

*Slurm* is a workload manager for Linux clusters [@slurm; @docs-slurm].
Unlike Lustre, Slurm operates in the user-space, not in the kernel space.
These computing resources include nodes, cores, memory, and time.
The access to the resources may be exclusive or nonexclusive, depending on the configuration.
We refer to such a resource allocation as a *job* in a job script.
An individual job may contain multiple *job steps* that may execute sequentially or in parallel.
Slurm provides a framework for starting, executing, and monitoring work on the allocated nodes.
Slurm groups nodes into *partitions*, which may be overlapping.
It also maintains a queue of jobs waiting for resources to become available for them to be started.
Slurm can also perform accounting for resource usage.


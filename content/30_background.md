\newpage

# Background
> - *What has been done previously?*
> - *What do we know about the research topic beforehand?*
> - *Balanced explanation of the whole research field.*

---

## Computer Clusters


## Linux operating system
At the time of writing, all high-performance computer clusters use the *Linux operating system* [@osfam].
The *Linux kernel* [@linuxkernel] is the core of the Linux operating system.
It derives from the original *UNIX operating system* and closely follows the *POSIX standard*. For a comprehensive overview of the features of the Linux kernel, we recommend and refer to *The Linux Programming Interface* book by Michael Kerrisk [@tlpi].

In this work, we will refer to the Linux kernel as the *kernel*.
The kernel is the central system that manages and allocates computer resources such as CPU, RAM, and devices.
It is responsible for tasks such as process scheduling, memory management, providing a file system, creating and termination of processes, access to devices, networking, and providing an application programming interface for system calls which makes the kernel services available to programs.
*System calls* enable user processes to request the kernel to perform certain actions for the process, such as file I/O, and provide separation between kernel space and user space.
Library functions, such as functions in the C standard library, implement caller friendly layer on top of system calls for performing system operations.

*Input/Output* (I/O) refers to the communication between a computer and the outside world, for example, a disk, display, or keyboard.
Linux implements a universal file I/O model, which means that it represents everything from data stored on disk to devices and processes as files.
It uses the same system calls for performing I/O on all types of files.
Consequently, the user can use the same file utilities to perform various tasks, such as reading and writing files or interacting with processes and devices.
The kernel only provides one file type, a sequential stream of bytes.
In this work, we focus on the storage file system I/O.

Linux is a *multiuser* system, which means that multiple users can use the computer at the same time.
The kernel provides an abstraction of a virtual private computer for each user, allowing multiple users to operate independently on the same computer system.
Linux systems have one special user, called the *super user* or *root user*, which has the privileges to access everything on the system.
The super user is used by *system administrators* for administrative tasks such as installing or removing software and system maintenance. [@tlpi: sections 2-3]

A *Linux distribution* comprises some version of the Linux kernel combined with a set of utility programs such as a shell, command-line tools, a package manager, and a graphical user interface.


## File system interface
The kernel provides an abstraction layer called *Virtual File System* (VFS), which defines a generic interface for file-system operations for concrete file systems.
This allows programs to use different file systems in a uniform way with the operation defined in the interface.
The interface contains the file system-specific system calls.
We explain the most important system calls below.
For in-depth documentation about system calls, we refer to *The Linux man-pages project* [@linuxmanpages: section 2].
We denote system calls using the syntax `systemcall()`.

- `mknod()` creates a new file (node).
- `open()` opens a file.
It returns a file descriptor to the file.
It may also create a new file.
- `close()` closes a file descriptor. Releases the resource from usage.
- `link()` creates a new hard link to an existing file. There can be multiple links to the same file.
- `unlink()` removes a hard link to a file.
If the removed hard link is the last hard link to the file, the file is deleted, and the space is made available for reuse.
- `mkdir()`
- `rmdir()`
- `rename()`
- `chown()`
- `chmod()`
- `stat()`
- `sync()`
- `read()`
- `write()`
- `fallocate()`
- `quotactl()`


## Client-Server architecture
A *client-server application* is an application that is broken into two processes, a client and a server.
The *client* requests a server to perform some service by sending a message.
The *server* examines the client's message, performs the appropriate actions, and sends a response message back to the client.
The client and server may reside in the same host computer or separate host computers connected by a network.
They communicate with each other by some Interprocess Communication (IPC) mechanism.
"Typically, the client application interacts with a user, while the server application provides access to some shared resource. Commonly, there are multiple instances of client processes communicating with one or a few instances of the server process." [@tlpi: section 2]


## Slurm job scheduling system
The Slurm documentation states, "Slurm is an open source, fault-tolerant, and highly scalable cluster management and job scheduling system for large and small Linux clusters." [@slurmdocs]


## Lustre cluster storage system
The Lustre documentation states, "The Lustre architecture is a storage architecture for clusters. The central component of the Lustre architecture is the Lustre file system, which is supported on the Linux operating system and provides a POSIX \*standard-compliant UNIX file system interface." [@lustredocs]


## Configuration on CSC Puhti
At the time of writing, CSC Puhti is using the *RedHat Enterprise Linux Server 7.9* distribution and is in transition to version 8.

```
$ cat /etc/redhat-release
Red Hat Enterprise Linux Server release 7.9 (Maipo)
```

The Lustre version is 

```
$ lctl --version
2.12.6_ddn72
```

The Slurm version is

```
$ sinfo --version
slurm 21.08.7-1_issue_803
```


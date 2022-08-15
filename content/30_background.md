\newpage

# Background
> - *What has been done previously?*
> - *What do we know about the research topic beforehand?*
> - *Balanced explanation of the whole research field.*

---

## Linux operating system
At the time of writing, all high-performance computer clusters use the *Linux operating system* [@osfam].
The *Linux kernel* [@linuxkernel] is the core of the Linux operating system.
It derives from the original *UNIX operating system* and closely follows the *POSIX standard*.

In this work, we will refer to the Linux kernel as the *kernel*.
The kernel is the central system that manages and allocates computer resources such as CPU, RAM, and devices.
It is responsible for tasks such as process scheduling, memory management, providing a file system, creating and termination of processes, access to devices, networking, and providing an application programming interface for system calls.
Furthermore, the kernel provides an abstraction of a virtual private computer for each user, allowing multiple users to operate independently on the same computer system. [@tlpi: section 2]

"A *system call* is a controlled entry point into the kernel, allowing a process to request that the kernel perform some action on the process’s behalf. The kernel makes a range of services accessible to programs via the system call application programming interface (API)."
[@tlpi: section 3]
Library functions, such as functions in the C standard library, implement caller friendly layer on top of system calls for performing system operations.

Typically, *Input/Output* (I/O) refers to the communication between a computer and outside world (for exapmle, a disk, display, or keyboard).
Linux implements a universal file I/O model, which means that it represents everything from data stored on disk to devices and processes as files.
It uses the same system calls for performing I/O on all types of files.
Consequently, the user can use the same file utilities to perform various tasks, such as reading and writing files or interacting with processes and devices.
In this work, we focus on the storage file system I/O.

For a comprehensive overview of the features of the Linux kernel, we recommend and refer to *The Linux Programming Interface* book by Michael Kerrisk [@tlpi].

A *Linux distribution* comprises some version of the Linux kernel combined with a set of utility programs such as a shell, command-line tools, a package manager, and a graphical user interface.


## Slurm job scheduling system
The Slurm documentation states, "Slurm is an open source, fault-tolerant, and highly scalable cluster management and job scheduling system for large and small Linux clusters." [@slurmdocs]


## Lustre cluster storage system
The Lustre documentation states, "The Lustre architecture is a storage architecture for clusters. The central component of the Lustre architecture is the Lustre file system, which is supported on the Linux operating system and provides a POSIX \*standard-compliant UNIX file system interface." [@lustredocs]


## File system interface
The file system forms a graph where the nodes are files that contain data.
That data may contain references to other files forming vertices in the graph.
Summary of Linux system calls for using the file system.
See *The Linux man-pages project* [@linuxmanpages: section 2].

```sh
man 2 mknod
```

---

- `mknod()` system call which creates a new file, that is, a new node in the file system.

- `open()` system call opens a file.
It returns a file descriptor to the file.

- `close()` system call which closes a file descriptor.

- `link()` system call which creates a new hard link to an existing file. There can be multiple links to the same file.

- `unlink()` which removes a hard link to a file.
If the removed hard link is the last hard link to the file, the file is deleted and the space is made available for reuse.

- `mkdir()`

- `rmdir()`

- `rename()`

- `chown()`

- `chmod()`

- `stat()`

- `getxattr()`

- `setxattr()`

- `statfs()`

- `sync()`

- `read()`

- `write()`

- `fallocate()`

- `quotactl()`


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


\newpage

# Background
> - *What has been done previously?*
> - *What do we know about the research topic beforehand?*
> - *Balanced explanation of the whole research field.*

---

## Linux operating system
The Linux operating system runs practically all high-performance computer clusters.
[[Why?]]

The Linux kernel [@linuxkernel] is the core of the Linux operating system.
The kernel is the central system that manages and allocates computer resources such as CPU, RAM, and devices.
It is responsible for tasks such as process scheduling, memory management, providing a file system, creating and termination of processes, access to devices, networking, and providing an application programming interface for system calls.
Furthermore, the kernel provides an abstraction of a virtual private computer for each user, allowing multiple users to operate independently on the same computer system.
[@tlpi: ch.2]
For a more comprehensive overview of the features of the Linux kernel, we recommend and refer to *The Linux Programming Interface* book by Michael Kerrisk [@tlpi].
In this work, we will refer to the Linux kernel as the kernel.

A Linux distribution comprises of some version of the Linux kernel combined with a set of utility programs such as a shell, command-line tools, a package manager and a graphical user interface.


## Lustre cluster storage system
Lustre documentation [@lustredocs]

> *"The Lustre architecture is a storage architecture for clusters. The central component of the Lustre architecture is the Lustre file system, which is supported on the Linux operating system and provides a POSIX \*standard-compliant UNIX file system interface."*


## Slurm job scheduling system
Slurm documentation [@slurmdocs]

> *"Slurm is an open source, fault-tolerant, and highly scalable cluster management and job scheduling system for large and small Linux clusters."*


## File system interface
The file system forms a graph where the nodes are file which contain data.
That data may contain references to other files forming vertices in the graph.
Summary of Linux system calls for using the file system.
See section 2 in *The Linux man-pages project* [@linuxmanpages].

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


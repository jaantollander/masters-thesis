\newpage

# Background
> - *What has been done previously?*
> - *What do we know about the research topic beforehand?*
> - *Balanced explanation of the whole research field.*

---

## Linux
Comprehensive overview of Linux concepts in the *The Linux Programming Interface* [@tlpi].

C programming language, system calls, file system


## Lustre
Lustre documentation [@lustredocs]

> *"The Lustre architecture is a storage architecture for clusters. The central component of the Lustre architecture is the Lustre file system, which is supported on the Linux operating system and provides a POSIX \*standard-compliant UNIX file system interface."*


## Slurm
Slurm documentation [@slurmdocs]

> *Slurm is an open source, fault-tolerant, and highly scalable cluster management and job scheduling system for large and small Linux clusters.*


## Linux file system
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


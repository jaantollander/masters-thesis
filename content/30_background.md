\newpage

# Background
> - *What has been done previously?*
> - *What do we know about the research topic beforehand?*
> - *Balanced explanation of the whole research field.*

---

*"The Lustre architecture is a storage architecture for clusters. The central component of the Lustre architecture is the Lustre file system, which is supported on the Linux operating system and provides a POSIX \*standard-compliant UNIX file system interface."* [@lustredocs]

---

Summary of Linux system calls for using the file system. See section 2 in Linux man pages project [@linuxmanpages].
[@tlpi]

`open()` system call opens a file.
It returns a file descriptor to the file.

`close()` system call which closes a file descriptor.

`mknod()` system call which creates a new file, that is, new file system node.

`link()` system call which creates a new hard link to an existing file.

`unlink()` which removes hard link to a file.
If it removes the last hard link to a file, the file is deleted and the space is made available for reuse.


# File system interface

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

: \label{tab:systemcalls}
This table lists the system calls for virtual file system.
For in-depth documentation about system calls, we recommend the Linux Man Pages [@man-pages, sec. 2].
In Linux, we can use `man 2 <system-call>` command to read the manual page of specific system call.


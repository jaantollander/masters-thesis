\clearpage
\thesisappendix


# Byte units
Value | Metric | Value | IEC
- | - | - | -
$1$ | byte (B) | $1$ | byte (B)
$1000^1$ | kilobyte (kB) | $1024^1$ | kibibyte (KiB)
$1000^2$ | megabyte (MB) | $1024^2$ | mebibyte (MiB)
$1000^3$ | gigabyte (GB) | $1024^3$ | gibibyte (GiB)
$1000^4$ | terabyte (TB) | $1024^4$ | tebibyte (TiB)
$1000^5$ | petabyte (PB) | $1024^5$ | pebibyte (PiB)

: Units for bytes in base $10$ and $2$.
  One byte is a string of $8$ bits.


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


# Programming with system calls
Next, we present two examples of performing file I/O using system calls.
Flags and modes are constants that modify the behaviour of an system call.
The bitwise-or of two modes or flags means that both of them apply.
Please note that these examples do not perform any error handling that should be done by proper programs.

## Read, write, open and close operations
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

## Punch operation
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


# Slurm job scripts
We can submit a job to the Slurm scheduler as a shell script via the `sbatch` command.
We can specify the options as command line arguments as we invoke the command or in the script as comments.
The script specifies job steps using the `srun` command.

## Small sequential job
```sh
#!/usr/bin/env bash
#SBATCH --job-name=<job-name>
#SBATCH --account=<project>
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
srun <program>
```

The above script is an example of a small, sequential batch job with a single job step (`srun` command).

## Multiple similar sequential jobs
```sh
#!/usr/bin/env bash
#SBATCH --job-name=<job-name>
#SBATCH --account=<project>
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --array=1-100
srun <program> $SLURM_ARRAY_TASK_ID
```

It is also common to run multiple such jobs independent of each other with slight variation for example in initial conditions.
We can achieve that by turning it into an array job by adding the `array` argument with desired range and accessing the array ID via an environment variable.

## Large parallel job
```sh
#!/usr/bin/env bash
#SBATCH --job-name=<job-name>
#SBATCH --account=<project>
#SBATCH --partition=large
#SBATCH --time=02:00:00
#SBATCH --nodes=2
#SBATCH --tasks-per-node=2
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=2G
#SBATCH --gres=nvme:100
# 1. job step
srun --nodes 2 --ntasks 1 <program-1>
# 2. job step
srun <program-2>
# 3. job step
srun --nodes 1 --ntasks 2 <program-3> &
# 4. job step
srun --nodes 1 --ntasks 2 <program-4> &
# Wait for job 2. and 3. to complete
wait
```

The above script is an example of a large parallel batch job with four job steps.
For example,
The first program will run on the first job step and could load data to the local disk.
The second program will run on the second job step utilizing all given nodes, tasks, and cpus and the majority of the given time.
It would be is a large parallel program such as a large, well parallelizing simulation communicating via MPI.
The third and fourth programs job steps will run in parallel after the first step, both utilizing all tasks and CPUs from a single node.
These programs could be programs for post processing steps, for example, processing and backing up the simulation results.


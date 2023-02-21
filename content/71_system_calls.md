\clearpage

# System calls
The next two examples present examples of performing file I/O using system calls.
Flags and modes are constants that modify the behavior of a system call.
The bitwise-or of two modes or flags means that both of them apply.
Please note that these examples do not perform any error handling that proper programs should do.
For in-depth documentation about system calls, we recommend the Linux Man Pages [@man-pages, sec. 2].

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

The first example program demonstrates opening and closing file descriptors, reading bytes from a file, and writing bytes to a file.
It opens `input.txt` in read-only mode, reads at most `size` bytes to a buffer, and then creates and writes them into the `output.txt` file in write-only mode.
The code performs the system calls `open`, `close`, `read`, and `write` with the flags `O_RDONLY`, `O_CREAT`, `O_WRONLY`, and modes `S_IRUSR` and `S_IWUSR`.
Furthermore, if the file does not already exist, the code calls `mknod` to create it.

\clearpage

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

The second example demonstrates a less common feature of punching a hole in a file, creating a sparse file.
The hole appears null bytes when reading the file without taking any space on the disk.
This feature is supported by certain Linux file systems such as ext4.
The following code writes `hello hole world` to an `output.txt` file.
It then deallocates bytes from 5 to 10 such that the file keeps its original size using `fallocate` with modes `FALLOC_FL_PUNCH_HOLE` and `FALLOC_FL_KEEP_HOLE`.


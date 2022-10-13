\newpage

# Methods
- *Describe the research material and methodology*


## Collecting operation statistics from Lustre file system
We can configure Lustre to collect file system usage statistics with *Lustre Jobstats*, as explained in the documentation, section 12.2 [@lustredocs, sec. 12.2].
Jobstats keeps counters of various statistics of file system related system calls.
Each Lustre server keeps counters for all of its targets.
We can query the values from the counter at given time by running the commands below on each server.

MDS jobstats:
: `lctl get_param mdt.*.jobstats`

OSS jobstats:
: `lctl get_param obdfilter.*.jobstats`

These commands fetch the values and prints them in a text format.
We can parse the output into a data structure for further processing using regular expressions.
The output for all targets on the same server is concatenated into a single output.
The raw output for each target is formatted as below.
We indicate variables using the syntax `<name>`.

---

```text
obdfilter.<source>.job_stats=
job_stats:
- job_id: <unique-identifier>
  snapshot_time: 1646385002
  <operation>: <statistics>
```

---

The `<source>` indicates the target of the data such as `scratch-MDT0000` or `scratch-OST0000`.
The `job_stats` contains entries for each workload with unique identifier that has performed file system operations on the target.
The `job_id` field contains a unique identifier in either of two formats:

1) `<jobcomment>.<uid>`
2) `<job>:<uid>:<nodename>`

The `jobcomment` contains a value of the program run in a Login node, `uid` is a user identifier, `job` is a Slurm job identifier, and `nodename` the node identifier.

Due to an unknown bug in the Lustre version 2.12.6, some of the identifiers are broken, for example, missing `job`, `uid` or `nodename` value, for small portion of jobs.
We discuss how to deal with these issue later.

The value in `snapshot_time` field contains a timestamp as a Unix epoch when the counter was last updated.
Finally, the output contains statistics of each operation specific to the target type, that is, MDT or OST.
The values are formatted as a key-value pairs separated by commas and enclosed within curly brackets.

---

```text
{ samples: 0, unit: <unit>, min: 0, max: 0, sum: 0, sumsq: 0 }
```

---

The `samples` field counts how many operations the job has performed since the counter was started.
The fields minimum (`min`), maximum (`max`), sum (`sum`) and sum of squares (`sumsq`) keep count of these aggregates values.
These fields contain a values that is a nonnegative integers that increases monotonically until the counter is reset.
A counter is reset if none of its values is updated in duration specified in the configuration, 10 minutes by default.
Units are (`<unit>`) either bytes (`bytes`) or microseconds (`usecs`).

Next, we list and explain the operations counted by jobstats.
Each operation counts statistic from calls to specific system calls.
Bolded monospace indicates an operation (**`operation`**) and brackets indicate a system call (`systemcall()`).

We have the following metadata operations performed on MDSs.

**`open`**
: `open()` and it variants
: Opening files.

**`close`**
: `close()` and its variants
: Closing files.

**`mknod`**
: `mknod()` and its variants
: Creating new files referred to as file system nodes.

**`link`**
: `link()` and its variants
: creating hard links. Does not count the first link created by `mknod()`.

**`unlink`**
: `unlink()` and variants
: removing hard links.

**`mkdir`**
: `mkdir()` and variants
: creating new directories.

**`rmdir`**
: `rmdir()` and variants
: removing empty directories.

**`rename`**
: `rename()` and variants
: renaming files and directories.

**`getattr`**
: `stat()`
: retrieve file access mode, ownership or timestamps.

**`setattr`**
: `chmod(), chown(), utime()` and variants
: setting file access mode, ownership or timestamps.

**`getxattr`**
: `getxattr()` and variants
: retrieving extended attributes.

**`setxattr`**
: `setxattr()` and variants
: setting extended attributes.

**`statfs`**
: `statfs()` and variants
: retrieving file system statistics.

**`sync`**
: `sync()` and variants
: invoking the kernel to write buffered metadata in memory to disk.

**`samedir_rename`**
: disambiguates which files are renamed within the same directory.

**`crossdir_rename`**
: disambiguates which files are moved to another directory potentially with under new name.

We have the following operations on the object data performed on OSSs.

**`read`**
: `read()` and variants
: reading data from a file.

**`write`**
: `write()` and variants
: writing data to a file.

**`getattr`**
: ???

**`setattr`**
: ???

**`punch`**
: `fallocate()`
: punching a hole in a file.

**`sync`**
: `sync()` and variants
: invoking the kernel to write buffered data in memory to disk.

**`get_info`**
: ???

**`set_info`**
: ???

**`quotactl`**
: `quotactl()`
: manipulate disk quota.

Additionally, we have two operations with bytes.

**`read_bytes`**
: `read()`
: number of bytes read from a file. Return value from `read()` system call and its variants.

**`write_bytes`**
: `write()`
: number of bytes written to a file. Return value from `write()` system call and its variants.

---

Lustre clients can cache certain file operations such as `open`.
That is, if `open` is called multiple times with same arguments Lustre client can serve it from the cache instead of having to request it from MDS.
Thus cached operations are not counted in the jobstats.
This means for example, that there can be more `close` than `open` operations counted, because `close` cannot be cached.


## Monitoring and recording the statistics
The pipeline for monitoring and recording the statistics consists of multiple instances of a monitoring daemon, and single instance of an ingest daemon and a relational database.
Daemon is a program that runs on the background.
We installed a monitoring daemon to each Lustre server on Puhti, and an ingest deamon along with a database to one of the Puhti's utility nodes.

The Monitoring daemon calls the appropriate `lctl get_param` command at regular intervals to collect statistics.
We found that 2 minute interval gives a sufficient resolution at manageable rate of data accumulation.
For each output and unique identifier (`job_id`) in `job_stats`, the program parses the values as below and place them into a data structure with the following fields:

- `snapshot_time` as an integer type.
- `uid` as an integer type.
- `job` as an integer type.
  We generate synthetic job ids for utility nodes and some of the broken identifier.
- `nodename` as a string type.
  Login node don't have `nodename` value, but set it to `login`.
- `source` as a string type.
- `jobcomment` as a string type. For `job_id`s without this value, we set it to an empty string.
- all `<operation>`s for target as integer types.
  We parse the values the `sum` values from `read_bytes` and `write_bytes` and `samples` from the others counts.
  We omit the rest of the values.

Each instance of the data structure represents a single row in the relational database.
The monitoring daemon sends this data to the ingest daemon.
The ingest program listens to the requests from the monitoring daemons and stores the data into a relational database.
We used a PostgreSQL with Timescale extension.

Due to issues in the identifiers (`job_id`s), we collected the counter values instead of calculating differences online.
This was contrary to our initial goal.
However, in order to develop a real-time monitoring system and to reduce the database size and improve query time, the processing must be done online.
We can efficiently store the differences into a tabular format for storage and analysis.


## Analyzing the statistics
* `(uid, job, nodename, source)` along time forms a timeseries
* we analyze each operation individually

We further process the data by computing a difference between two concecutive intervals, which tells us how many operations occured during the interval.

* First data point from a new job is lost.
* Detecting new jobs from the data (first appears on the output).
* Creating synthetic identifiers for missing and broken values.
* How many broken identifiers?


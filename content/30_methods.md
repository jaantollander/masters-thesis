\newpage

# Methods
- *Describe the research material and methodology*


## Collecting usage statistics from a Lustre file system
We can configure Lustre to collect file system usage statistics with *Lustre Jobstats*, as explained in the documentation [@lustredocs, sec. 12.2].
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

The `<source>` contains a value such as `scratch-MDT0000` or `scratch-OST0000` indicating the target of the data.
The `job_stats` contains entries for each workload with unique identifier that has performed file system operations on the target.
The `job_id` field contains a unique identifier in either of two formats:

Identifier for utility nodes:
: `<job-comment>.<uid>`

Identifier for compute nodes:
: `<job>:<uid>:<nodename>`

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
The `unit` is either bytes (`bytes`) or microseconds (`usecs`).


## File operations and statistics
Bolded monospace indicates a statistic (**`name`**) and monospace with brackets indicates a Linux system call (`name()`).

[Does jobstats only count succesful file operations?]

Job stats does not count cached operations.
For example, there may be more close than open operations counted.

We have the following operations for MDTs.
We keep their `samples` values and omit the other counts.

`open`
: collects the statistics from `open()`.

`close`
: collects the statistics from `close()`.

`mknod`
: collects statistics from `mknod()`.

`link`
: collects statistics from `link()`.

`unlink`
: collect statistic from `unlink()`.

`mkdir`
: make directory

`rmdir`
: remove directory

`rename`
: rename file

`getattr`
:  get attribute

`setattr`
:  set attribute

`getxattr`
:  get extended attribute

`setxattr`
:  set extended attribute

`statfs`
:  get file system statistics

`sync`
:  writes buffered data in memory to disk

`samedir_rename`
: todo

`crossdir_rename`
: todo

We have the following operations for OSTs. We keep their `samples` values and omit the other counts.

`read`
: todo

`write`
: todo

`setattr`
: todo

`punch`
: todo

`sync`
: todo

`get_info`
: todo

`set_info`
: todo

`quotactl`
: todo


Addtionally, we have two operations with bytes. We keep their `sum` counts.

`read_bytes`
: todo

`write_bytes`
: todo


## Processing the statistics
We furher process the data by computing a difference between two concecutive intervals, which tells us how many operations occured during the interval.
Each data point has the same fields for values and thus we can represent it in a tuple.
Multiple tuples form a table (aka relation), therefore, we can efficiently store the differences into a tabular format for storage and analysis.


## Problems with jobstats
The only way to detect a counter reset from the data is to observe if the value decreases.
However, if the value of counter grows larger after reset than it was before
reset, we cannot detect it.

First data point from a new job is lost.
Detecting new jobs from the data (first appears on the output).
Cached operations are not logged.

Handing missing values by adding synthetic values.
[Which values are missing? Why?]
[How many missing values? Compute from sample data.]

Due to a bug in Lustre version 2.?, the `<job>` values are missing for MPI jobs.


## Building a data pipeline
The data pipeline consists of a database, ingest program and monitoring program.

We installed a monitoring program, which runs on the background as a daemon, querying the values every two minutes, parses them and computes the difference.
The differences are sent to database via HTTP.

Ingest program listens to the requests from the monitoring program and stores them to a relational database.


## Analyzing the metrics


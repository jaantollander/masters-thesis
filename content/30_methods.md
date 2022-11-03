\newpage

# Methods
- *Describe the research material and methodology*


## Lustre Jobstats
We can configure Lustre to collect file system usage statistics with *Lustre Jobstats*, as explained in the documentation, section 12.2 [@lustredocs, sec. 12.2].
Jobstats keeps counters of various statistics of file system-related system calls.

We can specify the format `job_id` with `jobid_name` parameter in Lustre.
The formatting determines the granurarly of the statistics.
More granularity also means that we accumulate data faster.
We can use the following format codes.

- `%e` for executable name
- `%h` for fully-qualified hostname
- `%H` for short hostname (`%h` with everything after the first dot `.` is removed)
- `%j` for job ID from environment variable specified by `jobid_var` setting.
- `%u` for user ID number
- `%g` for group ID number
- `%p` for numeric process ID

We have set Lustre parameters `job_id_name="%j:%u:H"` and `jobid_var=SLURM_JOB_ID` to user Slurm job IDs for `%j`.
Then, we have two `job_id` formats:

`<job>:<uid>:<nodename>`
: with formatting string `"%j:%u:H"` when `SLURM_JOB_ID` is set.

`<executable>.<uid>`
: with formatting string `"%e.%u"` when `SLURM_JOB_ID` is undefined, such as for Login nodes.

Due to an unknown bug in Lustre (version 2.12.6), we found that some of the identifiers produced by Jobstats were missing or broken.
We discuss how to deal with these issues in later sections.


## Collecting statistics from the Lustre file system
Each Lustre server keeps counters for all of its targets.
We can query the values from the counter at a given time by running `lctl get_param` command.
These commands fetch the values and print them in a text format.
We can parse the output into a data structure for further processing using regular expressions.
The raw output for each target is formatted as below.
We indicate variables using the syntax `<name>`.

---

We can query jobstats from MDS as follows:

```sh
lctl get_param mdt.<source>.jobstats
```

The command output

```text
mdt.<source>.job_stats=
job_stats:
- job_id: <identifier_1>
  snapshot_time: <unix-epoch>
  <operation_1>: <statistics_1>
  <operation_2>: <statistics_2>
  ...
- job_id: <identifier_2>
  snapshot_time: <unix-epoch>
  <operation_1>: <statistics_1>
  <operation_2>: <statistics_2>
  ...
```

---

We can query jobstats from OSS as follows:

```sh
lctl get_param obdfilter.<source>.jobstats
```

```text
obdfilter.<source>.job_stats=
job_stats:
- job_id: <identifier_1>
  snapshot_time: <unix-epoch>
  <operation_1>: <statistics_1>
  <operation_2>: <statistics_2>
  ...
- job_id: <identifier_2>
  snapshot_time: <unix-epoch>
  <operation_1>: <statistics_1>
  <operation_2>: <statistics_2>
  ...
```

---

The `<source>` indicates the target of the data.
In Puhti, `scratch-MDT0000` or `scratch-OST0000`.

The `job_stats` contains entries for each workload with the unique identifier `job_id` that has performed file system operations on the target.


The value in `snapshot_time` field contains a timestamp as a Unix epoch when the counter was last updated.
Finally, the output contains statistics of each operation specific to the Lustre target; that is, MDT and OST track different operations.
The values are formatted as key-value pairs separated by commas and enclosed within curly brackets.

---

```text
{ samples: 0, unit: <unit>, min: 0, max: 0, sum: 0, sumsq: 0 }
```

---

The `samples` field counts how many operations the job has performed since the counter was started.
The fields minimum (`min`), maximum (`max`), sum (`sum`), and the sum of squares (`sumsq`) keep count of these aggregates values.
These fields contain nonnegative integers that increase monotonically except in counter resets.
A counter is reset if none of its values are updated in the duration specified in the configuration, 10 minutes by default.
Units are (`<unit>`) either bytes (`bytes`) or microseconds (`usecs`).


## Operations
operation | system call | notes
---|--|------
**`open`** | `open`
**`close`** | `close`
**`mknod`** | `mknod`
**`link`** | `link` |  Does not count the first link created by `mknod`.
**`unlink`** | `unlink`
**`mkdir`** | `mkdir`
**`rmdir`** | `rmdir`
**`rename`** | `rename`
**`getattr`** | `stat` | Retrieve file attributes.
**`setattr`** | `chmod`, `chown`, `utime` | Set file attributes
**`getxattr`** | `getxattr` | Retrieving extended attributes.
**`setxattr`** | `setxattr` | Setting extended attributes.
**`statfs`** | `statfs` | Retrieving file system statistics.
**`sync`** | `sync` | Invoking the kernel to write buffered metadata in memory to disk.
**`samedir_rename`** || Disambiguates which files are renamed within the same directory.
**`crossdir_rename`** || Disambiguates which files are moved to another directory, potentially under a new name.

: \label{tab:mdt-operations} We have the following metadata operations performed on MDSs.


operation | system call | notes
---|--|------
**`read`** | `read` | Reading data from a file.
**`write`** | `write` | Writing data to a file.
**`getattr`** | 
**`setattr`** | 
**`punch`** | `fallocate` | Punch a hole in a file.
**`sync`** | `sync` | Invoking the kernel to write buffered data in memory to disk.
**`get_info`** | 
**`set_info`** | 
**`quotactl`** | `quotactl` | Manipulate disk quota.
**`read_bytes`** | `read` | Number of bytes read from a file. Return value from `read` system call.
**`write_bytes`** | `write` | Number of bytes written to a file. Return value from `write` system call.

: \label{tab:ost-operations} We have the following operations on the object data performed on OSSs.

In tables \ref{tab:mdt-operations} and \ref{tab:ost-operations}, we list and explain the operations counted by Jobstats.
We have omitted some rarely encountered operations from the tables.
Each operation counts statistics from calls to specific system calls.

Lustre clients may cache certain file operations such as `open`.
That is if `open` is called multiple times with the same arguments Lustre client can serve it from the cache instead of having to request it from MDS.
Thus, cached operations are not counted in the Jobstats, which means, for example, that there can be more `close` than `open` operations because `close` cannot be cached.


## Monitoring and recording the statistics
![](figures/lustre-monitor.drawio.svg)

The pipeline for monitoring and recording the statistics consists of multiple instances of a monitoring daemon and a single instance of an ingest daemon, and a relational database.
*Daemon* is a program that runs in the background.
We installed a monitoring daemon to each Lustre server, and an ingest daemon and a database to a utility node on Puhti.

The Monitoring daemon calls the appropriate `lctl get_param` command at regular intervals to collect statistics.
We found that a 2-minute interval gives a sufficient resolution at a manageable rate of data accumulation.
We record the time when we collected the statistics as `timestamp`.
For each output and unique identifier (`job_id`) in `job_stats`, the program parses the values below and places them into a data structure with the following fields along with the `timestamp` field.

- `snapshot_time` to an integer type.
- `uid` to an integer type.
- `job` to an integer type.
  We generate synthetic `job` IDs for utility nodes and identifiers where only `job` is missing, but `uid` and `nodename` are intact.
- `nodename` to a string type.
- `source` to a string type.
  Login node don't have `nodename` value, thus we set it to `login`.
- `executable` to a string type. We set it to an empty string for `job_id`s without this value.
- all `<operation>`s for target to integer types.
  We parse the values the `sum` values from `read_bytes` and `write_bytes` and `samples` from the other counts.
  We omit the rest of the values.

The monitoring daemons send these data structures to the ingest daemon in batches.
The ingest daemon listens to the requests from the monitoring daemons and stores the data in a relational database such that each instance of the data structure represents a single row.
We used a PostgreSQL database with a Timescale extension.


## Issues with identifiers
`job_id` | notes
-|-
`11317854:17627127:r01c01` | correct identifier
`:17627127:r01c01` | `job` missing
`11317854` | `job` field
`11317854:` | `job` field and separator `:`
`113178544` | `job` field with extra character at the end
`11317854:17627127` | `job` and `uid` fields
`11317854:17627127:` | `job` and `uid` fields ending with a separator
`11317854:17627127:r01c01.bullx` | fully-qualified hostname instead of a short hostname
`:17627127:r01c01.bullx` | `job` field is missing and fully qualified hostname instead of a short hostname
`:1317854:17627127:r01c01` | the first character in `job` overwritten by separator

: `<job>`, `<uid>`, and `<nodename>` separated with colon `:`

We found formatting issues with `job_id` identifiers in the generated data from Lustre Jobstats on the Puhti system.
For example, we found many identifiers without the value in the `job` field on MDS and OSS data from compute nodes.

Furthermore, on the OSS, `job_id`s had issues such as values missing from `uid` and `nodename` fields or fully-qualified hostname instead of the specified short hostname in the `nodename` field.
Even more problematic was that sometimes `job_id` was malformed to the extent that we could not reliably parse information from it.
For example, there were characters in the identifiers missing, overwritten, or duplicated.
We had to discard these entries completely.
We suspect that data race might be causing some of these issues.

---

> TODO: add plot of counted job ids

`job` | `uid` | `nodename` | \# entries with user or missing uid | % | \# entries with system uid | %
:-:|:-:|:-:|-:|-:|-:|-:
-|uid|login|55077|24.19|6132|4.81
job|uid|compute|145590|63.93|36909|28.98
-|uid|compute|21037|9.24|84275|66.17
-|uid|puhti|6012|2.64|45|0.04
||||227716||127361|


: MDS entries \label{tab:mds-entries}


`job` | `uid` | `nodename` | \# entries with user or missing uid | % | \# entries with system uid | %
:-:|:-:|:-:|-:|-:|-:|-:
-|uid|login|271561|16.85|10074|1.61
job|uid|compute|1126289|69.88|2003|0.32
-|uid|compute|187101|11.61|610189|97.70
-|uid|puhti|9674|0.60|1519|0.24
job|uid|compute (q)|2655|0.16
-|uid|compute (q)|43|<0.01|237|0.04
job|uid|-|4769|0.30
job|-|-|6928|0.43
-|uid|-|67|<0.01|540|0.09
-|-|-|2766|0.17
||||1611853||624562|

: OSS entries \label{tab:oss-entries}

For example, the tables \ref{tab:mds-entries} and \ref{tab:oss-entries} show the counts of entries of a sample of 113 consecutive 2-minute intervals for MDSs and OSSs separated by normal or missing `uid`s and system `uid`s for different `job_id` compositions.
In the table, "job" indicates that job ID exists, "uid" indicates user ID exists, dash "-" indicates missing value, "login" indicates login node, "compute" indicates compute node, "(q)" indicates fully-qualified nodename and "puhti" indicates node that is not login or compute node.

As a consequence of these issues, data from the same job might be scattered into multiple time series without reliable indicators making it impossible to provide reliable job-specific statistics.
Also, discarded entries lead to some data loss.
The reliability of the counter data does not seem to be affected by this issue.


## Computing rates of change from the statistics
> TODO: add plot of raw counter values and computed rate of change, generate fake data

For a row in the relational database, the tuple of values `(uid, job, nodename, source)` forms a unique identifier, `timestamp` is time, and `<operation>` fields contain the counter values for each operation.

For each unique identifier, each counter value $v\in\mathbb{R}$ such that $v\ge 0$ of an operation along time $t\in\mathbb{R}$ form a time series.
Given two points consequtive points in the time series, $(t, v)$ and $(t^\prime, v^\prime)$ where $t < t^\prime,$ we can calculate the *interval length* as $\Delta t > 0$ and *number of operations* $\Delta v > 0$ during the interval.
The interval length is

$$\Delta t = t^{\prime} - t.$$

If $v^\prime \ge v$, the previous counter value is incremented, and we have $\Delta v = v^\prime - v.$
Otherwise, if $v^\prime < v$, the counter has reset and the previous counter value is implicitly zero, and we have $\Delta v = v^\prime - 0.$
Combined, we can write

$$\Delta v = 
\begin{cases}
v^{\prime} - v, & v^{\prime} \ge v \\
v^{\prime}, & v^{\prime} < v
\end{cases}.$$

Then, we can calculate the *average rate of change* during the interval for each operation as

$$r=\Delta v / \Delta t.$$

If a particular `job_id` has not yet performed any operations, its counters contain implicit zeros, that is, they not in the output of the statistics.
In these cases, we can infer the *initial counter* $(t_0, v_0)$ where $v_0=0$ and set $t_0$ to the timestmap of last recording interval.
For the first recording interval, we cannot infer $t_0$ and we need to discard the initial counter.
The *observed counters* are $(t_1,v_1),...,(t_n,v_n),$ where $n\in\mathbb{N}.$
Then, given a series of counter values

$$(t_0, v_0), (t_1, v_1), (t_2, v_2), ..., (t_{n-1}, v_{n-1}), (t_n, v_n),$$

we can compute the series of average rates of change $r_i$ in the interval $[t_i,t_{i+1})$ as described previously and obtain

$$(t_0, r_0), (t_1, r_1), (t_2, r_2),...,(t_{n-1}, r_{n-1}), (t_n, r_n),$$

where $r_n=0,$ that is, the rate of change when there is no more counter values is set to zero.
Mathematically, the average rate of change forms a step function such that

$$r(t)=\begin{cases}
0, & t < t_{0} \\
r_i, & t_i \le t < t_{i+1}, \forall i\in\{0,...,n-1\} \\
0, & t \ge t_n
\end{cases},$$

where the rate of change is zero before we have observed any values, formally $t < t_{0}.$

We can recover the changes in counter values from the step function using an integral

$$\Delta v_{i}=\int_{t_{i}}^{t_{i+1}} r(t)\,dt = r_{i} \cdot (t_{i+1}-t_{i}) = r_{i}\cdot\Delta t_{i},\quad \forall i\in\{1,...,n-1\}.$$

We can transform a step function $r(t)$ into a step function $r^\prime(t)$ defined by 

$$(t_0^\prime, r_0^\prime), (t_1^\prime, r_1^\prime), (t_2^\prime, r_2^\prime),...,(t_{m-1}^\prime, r_{m-1}^\prime), (t_m^\prime, r_m^\prime),\quad m\in\mathbb{N}$$

where
$r_{j}^{\prime} = \Delta v_{j}^{\prime} / \Delta t_{j}^{\prime}$ and
$\Delta t_{j}^{\prime} = (t_{j+1}^\prime - t_{j}^\prime)$
such that it preserves the change in counter values in the new intervals

$$
\Delta v_{j}^\prime = 
\int_{t_{j}^\prime}^{t_{j+1}^\prime} r^\prime(t)\,dt = 
\int_{t_{j}^\prime}^{t_{j+1}^\prime} r(t)\,dt, \quad \forall j\in\{0,...,m-1\}.
$$

This transformation is useful if we have multiple step functions with steps as different timestamp and we need to convert the steps to happen at same timestamps.
In practice, we can avoid the transformation by querying the counters at same times and using them as timestamps.


## Visualizing rates of change
> TODO: add plot of sum aggregate and heatmaps

> TODO: add another plot with different resolution

We can visualize an individual time series as step plot.
However, our configuration produces thousands of individual time series.
To visualize multiple time series, we must either compute an aggregate such as as sum or plot a heatmap of the distribution of values in each interval.

We define logarithmic binning function with *base* $b > 1$ as

$$f_{b}(x)=\lfloor \log_{b}(x) \rfloor.$$

We define an indicator function for counting values as follows

$$\mathbf{1}_{a}(x)=\begin{cases}
1, & x=a \\
0, & x\ne a
\end{cases}.$$

Let $R$ be a set of step functions such that steps occur at same times $t.$
Then, we can count many step values occur in the range $[b^k,b^{k-1})$ with base $b$ for bin $(t, k)$ as follows

$$z_{b}(t, k)=\sum_{r\in R} \mathbf{1}_{k}(f_b(r(t))).$$

The base parameter determines the *resolution* of the binning.


## Querying the database


## Heuristics for measuring lag on the Lustre file system


## Notes
Due to issues in the identifiers (`job_id`s), we collected the counter values instead of calculating differences online.
This was contrary to our initial goal.
However, in order to develop a real-time monitoring system and to reduce the database size and improve query time, the processing must be done online.
We can efficiently store the differences into a tabular format for storage and analysis.
Implement as stream processing.


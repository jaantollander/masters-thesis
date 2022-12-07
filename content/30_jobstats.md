\newpage

# File system usage statistics
## Overview
TODO: improve overview

We described the architecture of the Lustre parallel file system in Section \ref{lustre-parallel-file-system}.
Now, we focus on enabling the monitoring in Lustre with Jobstats, covering important settings for Jobstats, the kinds of statistics it tracks, how to query them, and the format of the query output.
We also explain issues we encountered using the Jobstats, such as missing and broken identifiers.
We explain these in the context of the Puhti cluster described in Section \ref{puhti-cluster-at-csc}.

Due to the issues we found, we recommend experimenting with the settings, recording large raw dumps of the statistics, and analyzing them offline before building a more complex monitoring system.

The Lustre monitoring and statistics guide [@lustre-monitoring-guide] presents a general framework and software tools for gathering, processing, storing, and visualizing file system statistics from Lustre.


## Entry identifier format
We can enable Jobstats by specifying a formatting string for the *entry identifier* using the `jobid_name` parameter on a Lustre client as explained in the *Lustre Manual* [@docs-lustre, sec. 12.2].
We can configure each Lustre client separately and specify different configurations for different clients.
We can use the following format codes.

- `%e` for *executable name*.
- `%h` for *fully-qualified hostname*.
- `%H` for *short hostname* aka *nodename*, that is, the fully-qualified hostname such that everything after the first dot including the dot is removed.
- `%j` for *Job ID* from environment variable specified by `jobid_var` setting.
- `%u` for *User ID* number.
- `%g` for *Group ID* number.
- `%p` for *Process ID* number.

The formatting effects the resolution of the statistics.
Using more formatting codes results in higher resolution but also leads to higher rate of data accumulatation.

For Lustre client on login nodes, the formatting includes the *Executable name* and User ID.

```
    jobid_name="%e.%u"
```

For Lustre client on compute and utility nodes, the formatting includes *Slurm Job ID*, User ID and nodename.

```
    jobid_name="%j:%u:%H"
    jobid_var=SLURM_JOB_ID
```

We can use the Slurm job ID to retrieve Slurm job information such as project and partition.
For example, the project could also be useful for identifying if members of a particular project perform problematic file I/O patterns.


## Operations and statistics
Each Lustre server keeps counters for all of its targets.
We can fetch the counters and print them in a text format by running `lctl get_param` command with an argument that points to the desired jobstats.

---

We can query jobstats from MDS as follows:

```sh
    lctl get_param mdt.<target>.jobstats
```

The text output is formatted as follows.

```text
    mdt.<target>.job_stats=
    job_stats:
    - job_id: <entry_id_1>
      snapshot_time: <snapshot_time_1>
      <operation_1>: <statistics_1>
      <operation_2>: <statistics_2>
      ...
    - job_id: <entry_id_2>
      snapshot_time: <snapshot_time_2>
      <operation_1>: <statistics_1>
      <operation_2>: <statistics_2>
      ...
```

---

Similarly, we can query jobstats from OSS as follows:

```sh
    lctl get_param obdfilter.<target>.jobstats
```

The text output is also similar.

```text
    obdfilter.<target>.job_stats=
    job_stats:
    - job_id: <entry_id_1>
      snapshot_time: <snapshot_time_1>
      <operation_1>: <statistics_1>
      <operation_2>: <statistics_2>
      ...
    - job_id: <entry_id_2>
      snapshot_time: <snapshot_time_2>
      <operation_1>: <statistics_1>
      <operation_2>: <statistics_2>
      ...
```

---

The *target* (`<target>`) contains the mount point and name of Lustre target of the query.
In Puhti, we have two MDSs with two MDTs each, named `scratch-MDT<index>` and eight OSSs with three OSTs each, named `scratch-OST<index>`.
The `<index>` is four digit integer in hexadecimal format using the characters `0-9a-f` to represent digits.
Indexing starts from zero.
For example, we have targets such as `scratch-MDT0000`, `scratch-OST000f`, and `scratch-OST0023`.

After the `job_stats` line, we have a list of entries for workloads that have performed file system operations on the target.
Each *entry* is denoted by dash `-` and contains the entry identifier (`job_id`), *snapshot time* (`snapshot_time`) and various operations with statistics.
The value of snapshot time is a timestamp as a Unix epoch when the statistics of one of the operations was last updated.
*Unix epoch* is the standard way of representing time in Unix systems.
It measures time as the number of seconds that has elapsed since 00:00:00 UTC on 1 January 1970, exluding leap seconds.

Table \ref{tab:operations} list the operations and corresponding system calls counted by Jobstats for MDTs and OSTs.
We have omitted some rarely encountered operations from the tables.
Each operation (`<operation>`) contains line of statistics (`<statistics>`) which are formatted as key-value pairs separated by commas and enclosed within curly brackets:

```text
    { samples: 0, unit: <unit>, min: 0, max: 0, sum: 0, sumsq: 0 }
```

The samples (`samples`) field counts how many operations the job has requested since the counter was started.
The fields minimum (`min`), maximum (`max`), sum (`sum`), and the sum of squares (`sumsq`) keep count of these aggregates values.
These fields contain nonnegative integer values.
The samples, sum, and sum of squares increase monotonically unless reset.
Units (`<unit>`) are either request (`reqs`), bytes (`bytes`) or microseconds (`usecs`).
Statistics of an entry that has not performed any operations are implicitly zero.


Targets | Operation | System call | Parsed statistics
-|-|-|-
MDT | **`open`** | `open` | `samples`
MDT | **`close`** | `close` | `samples`
MDT | **`mknod`** | `mknod` | `samples`
MDT | **`link`** | `link` | `samples`
MDT | **`unlink`** | `unlink` | `samples`
MDT | **`mkdir`** | `mkdir` | `samples`
MDT | **`rmdir`** | `rmdir` | `samples`
MDT | **`rename`** | `rename` | `samples`
MDT, OST | **`getattr`** | `stat` | `samples`
MDT, OST | **`setattr`** | `chmod`, `chown`, `utime` | `samples`
MDT | **`getxattr`** | `getxattr` | `samples`
MDT | **`setxattr`** | `setxattr` | `samples`
MDT\textcolor{lightgray}{, OST} | **`statfs`** | `statfs` | `samples`
MDT, OST | **`sync`** | `sync` | `samples`
MDT | **`samedir_rename`** | `rename` | `samples`
MDT | **`crossdir_rename`** | `rename` | `samples`
OST | **`read`** | `read` | `samples`
OST | **`write`** | `write` | `samples`
\textcolor{lightgray}{MDT,} OST | **`punch`** | `fallocate` | `samples` 
OST | **`get_info`** | | `samples`
OST | **`set_info`** | | `samples`
OST | **`quotactl`** | `quotactl` | `samples`
\textcolor{lightgray}{MDT,} OST | **`read_bytes`** | `read` | `sum`
\textcolor{lightgray}{MDT,} OST | **`write_bytes`** | `write` | `sum`
\textcolor{lightgray}{OST} | **`create`** | 
\textcolor{lightgray}{OST} | **`destroy`** | 
\textcolor{lightgray}{OST} | **`prealloc`** | 

: \label{tab:operations}
All operations tracked by the Jobstats for each Lustre target.
We mentioned system calls in Section \ref{linux-operating-system}.
You can find explanation of relevant system calls in Appendix \ref{file-system-interface}.
For the details about the **`punch`** operation, see the Appendix \ref{punch-operation}.
The \textcolor{lightgray}{light gray} operation names indicates that the operation field is present in the output, but we did not include it our analysis.


We found that the counters may report more samples for `close` than `open` operations.
It should not be possible to do more `close` than `open` system calls because a file descriptor returned by open can be closed only once.
We suspect that the Lustre clients cache certain file operations and Jobstast does not count cached operations.
For example, if `open` is called multiple times with the same arguments Lustre client can serve it from the cache instead of having to request it from MDS thus request is not recorded.


## Entry resets
If Jobstats has not updated the statistics of an entry within the *cleanup interval*, it removes the entry.
That is if the snapshot time is older than the cleanup interval.
We can specify the cleanup interval in the configuration using the `job_cleanup_interval` parameter.
The default cleanup interval is 10 minutes.

The removal of an entry *resets* the entry.
If a job subsequently performs more operations, we can detect the reset by looking if any of the counter values have decreased.
This method does not detect reset if the new counter value is larger than the old one, but it is uncommon because counter values typically grow large.
We will underestimate the counter increment in this case when calculating the difference between two counter values.


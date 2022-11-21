\newpage

# Collecting usage statistics with Lustre Jobstats
## Overview
In section \ref{lustre-parallel-file-system}, we described Lustre parallel file system and in section \ref{puhti-cluster-at-csc}, we described the Puhti cluster.

We can configure Lustre to collect file system usage statistics with *Lustre Jobstats*, as explained in the section 12.2 of Lustre manual [@lustredocs, sec. 12.2].
Jobstats keeps counters of various statistics of file system-related system calls.

## Setting identifier format for entries
We can enable Jobstats by specifying a formatting string for the *entry identifier* using the `jobid_name` parameter.
We can use the following format codes.

- `%e` for *executable name*.
- `%h` for *fully-qualified hostname*.
- `%H` for short hostname aka *nodename*, that is, `%h` such that everything after the first dot (`.`) is removed.
- `%j` for *Job ID* from environment variable specified by `jobid_var` setting.
- `%u` for *User ID* number.
- `%g` for *Group ID* number.
- `%p` for *Process ID* number.

The formatting effects the resolution of the statistics.
Using more formatting codes results in higher resolution but also leads to higher rate of data accumulatation.

We have set the entry identifier to include *Slurm Job ID*, User ID and nodename.
It is used for compute and utility nodes.

```
jobid_name="%j:%u:%H"
jobid_var=SLURM_JOB_ID
```

The default formatting string includes the *Executable name* and User ID.
It is used for login nodes..

```
jobid_name="%e.%u"
```

We did not record the Group ID, but it could also be useful for identifying if members of a particular group perform problematic file I/O patterns.


## Querying statistics
Each Lustre server keeps counters for all of its targets.
We can fetch the counters and print them in a text format by running `lctl get_param` command with an argument that points to the desired jobstats.

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
The prefix `scratch-` indicates that we measure the usage of in the `scratch` storage area.
The `<index>` is four digit integer in hexadecimal format using the characters `0-9a-f` to represent digits.
Indexing starts from zero.
For example, we have targets such as `scratch-MDT0000`, `scratch-OST000f`, and `scratch-OST0023`.

After the `job_stats` line, we have a list of entries for workloads that have performed file system operations on the target.
Each *entry* is denoted by dash `-` and contains the entry identifier (`job_id`), *snapshot time* (`snapshot_time`) and various operations with statistics.
The value of snapshot time is a timestamp as a Unix epoch when the statistics of one of the operations was last updated.
*Unix epoch* is the standard way of representing time in Unix systems.
It measures time as the number of seconds that has elapsed since 00:00:00 UTC on 1 January 1970, exluding leap seconds.

Next, we explain the file operations and statistics.


## File operations and statistics
Operation | System call | Parsed statistics
---|--|------
**`open`** | `open` | `samples`
**`close`** | `close` | `samples`
**`mknod`** | `mknod` | `samples`
**`link`** | `link` | `samples`
**`unlink`** | `unlink` | `samples`
**`mkdir`** | `mkdir` | `samples`
**`rmdir`** | `rmdir` | `samples`
**`rename`** | `rename` | `samples`
**`getattr`** | `stat` | `samples`
**`setattr`** | `chmod`, `chown`, `utime` | `samples`
**`getxattr`** | `getxattr` | `samples`
**`setxattr`** | `setxattr` | `samples`
**`statfs`** | `statfs` | `samples`
**`sync`** | `sync` | `samples`
**`samedir_rename`** | `rename` | `samples` (Count of files are renamed within the same directory.)
**`crossdir_rename`** | `rename` | `samples` (Count of files are moved to another directory, potentially under a new name.)

: \label{tab:mdt-operations}
We have the following metadata operations performed on MDSs.


Operation | System call | Parsed statistics
---|--|------
**`read`** | `read` | `samples`
**`write`** | `write` | `samples`
**`getattr`** | `samples`
**`setattr`** | `samples`
**`punch`** | `fallocate` | `samples` (see appendix \ref{punch-operation} for details)
**`sync`** | `sync` | `samples`
**`get_info`** | | `samples`
**`set_info`** | | `samples`
**`quotactl`** | `quotactl` | `samples`
**`read_bytes`** | `read` | `sum` (sum of return values from `read`)
**`write_bytes`** | `write` | `sum` (sum of return values from `write`)

: \label{tab:ost-operations}
We have the following operations on the object data performed on OSSs.

In tables \ref{tab:mdt-operations} and \ref{tab:ost-operations}, we list the operations and corresponding system calls counted by Jobstats for MDTs and OSTs.
We have omitted some rarely encountered operations from the tables.
Each operation (`<operation>`) contains line of statistics (`<statistics>`) which are formatted as key-value pairs separated by commas and enclosed within curly brackets.

---

```text
{ samples: 0, unit: <unit>, min: 0, max: 0, sum: 0, sumsq: 0 }
```

---

The `samples` field counts how many operations the job has requested since the counter was started.
The fields minimum (`min`), maximum (`max`), sum (`sum`), and the sum of squares (`sumsq`) keep count of these aggregates values.
These fields contain nonnegative integer values.
The `samples`, `sum`, and `sumsq` values increase monotonically.
Units (`<unit>`) are either request (`reqs`), bytes (`bytes`) or microseconds (`usecs`).
Statistics of an entry that has not performed any operations yet are implicitly zero.

We found that the counters may report more samples for `close` than `open` operations.
It should not be possible to do more `close` than `open` system calls because a file descriptor returned by open can be closed only once.
We suspect that the Lustre clients cache certain file operations and Jobstast does not count cached operations.
For example, if `open` is called multiple times with the same arguments Lustre client can serve it from the cache instead of having to request it from MDS thus request is not recorded.


## Detecting resets
Jobstats removes an entry if none of its statistics are updated within the *cleanup interval* specified in the configuration as `job_cleanup_interval` parameter.
That is, Jobstats automatically removes entries with snapshot time older than the cleanup interval.
The default cleanup interval is 10 minutes.

> TODO: there is no certain way of detecting resets, not sure if looking at snapshot times if totally reliable, over estimation is worse than underestimating counter increments, simplicity

We refer to the removal of an entry as *reset*.
In pratice, we detect a *reset* by detecting if any of the counter values decrease which can only happen if the entry.
This method might underestimate increment if counter resets and then does more operations than last count.


## Issues with entry identifiers

Type | Entry identifier | Notes
-|-----|-----
0 |`11317854:17627127:r01c01` | Correct format
1|`:17627127:r01c01` | Job ID missing
2|`11317854` | `job` field without separator
2|`11317854:` | `job` field with separator
2|`113178544` | `job` field with separator at the end is overwritten by a digit
2|`11317854:17627127` | `job` and `uid` fields
2|`11317854:17627127:` | `job` and `uid` fields ending with a separator
2|`11317854:17627127:r01c01.bullx` | fully-qualified hostname instead of a short hostname
2|`:17627127:r01c01.bullx` | `job` field is missing and fully qualified hostname instead of a short hostname
2|`:1317854:17627127:r01c01` | the first character in `job` overwritten by separator

: \label{tab:jobid-examples}
Examples of various observed entry identifiers on compute nodes.
We refer to colon (`:`) as *separator*.

Unfortunately, we found two separate issues with the entry identifiers on the Puhti system.
That is, did not conform to the format described in Section \ref{setting-identifier-format-for-entries}.

The first type of issue is missing Job ID values in some entries from normal user in compute nodes even thought the `SLURM_JOB_ID` environment variable is set.
It might be related to some issues in fetching the value of the environment variable.
This issues occured in both MDS and OSS.

The second type of issue is that some entry identifiers were malformed.
We cannot reliably parse Job ID, User ID, and Nodename information from these entry identifiers.
It occured only in OSS.
We believe that this issue is related to lack of thread-safety in some of the functions that produce the entry identifier strings.
[@jobid-atomic]

Table \ref{tab:jobid-examples} demonstrates some of the entry identifiers we found.

<!-- TODO: add plot of counted job ids in respect to time -->

Job ID | User ID | Nodename | Count | Ratio
:-:|:-:|:-:|-:|-:|-:|-:
-|user|login|55077|24.19
slurm|user|compute|145590|63.93
-|user|compute|21037|9.24
-|user|utility|6012|2.64
||||227716

: \label{tab:jobids-mds-user}
MDS, user

Job ID | User ID | Nodename | Count | Ratio
:-:|:-:|:-:|-:|-:|-:|-:
-|system|login|6132|4.81
slurm|system|compute|36909|28.98
-|system|compute|84275|66.17
-|system|utility|45|0.04
||||127361

: \label{tab:jobids-mds-system}
MDS system

Job ID | User ID | Nodename | Count | Ratio
:-:|:-:|:-:|-:|-:|-:|-:
-|user|login|271561|16.85
slurm|user|compute|1126289|69.88
-|user|compute|187101|11.61
-|user|utility|9674|0.60
slurm|user|compute (q)|2655|0.16
-|user|compute (q)|43|<0.01
slurm|user|-|4769|0.30
slurm|-|-|6928|0.43
-|user|-|67|<0.01
-|-|-|2766|0.17
||||1611853

: \label{tab:jobids-oss-user}
OSS, user

Job ID | User ID | Nodename | Count | Ratio
:-:|:-:|:-:|-:|-:|-:|-:
-|system|login|10074|1.61
slurm|system|compute|2003|0.32
-|system|compute|610189|97.70
-|system|utility|1519|0.24
slurm|system|compute (q)|0|0
-|system|compute (q)|237|0.04
slurm|system|-|0|0
slurm|-|-|0|0
-|system|-|540|0.09
-|-|-|0|0
||||624562|

: \label{tab:jobids-oss-system}
OSS system


The Tables \ref{tab:jobids-mds-user}, \ref{tab:jobids-mds-system}, \ref{tab:jobids-oss-user}, and \ref{tab:jobids-oss-system} show the counts of different entry identifiers in a sample of 113 consecutive 2-minute intervals from all MDSs and OSSs.
In the tables, dash *-* indicates missing value, *system* is User ID reserved for ssystem processes, *user* is User ID reverved for user processes, *slurm* is Slurm Job ID, *login* is login Nodename, *compute* is compute Nodename, *utility* is utility Nodename and *compute (q)* is fully-qualified hostname for compute node.

TODO: difference between MDS and OSS, missing job, thread safety issues

As a consequence of these issues, data from the same job might be scattered into multiple time series without reliable indicators making it impossible to provide reliable statistics for specific identifiers.

Also, discarded entries lead to some data loss.
The reliability of the counter data does not seem to be affected by this issue.

<!-- TODO: system uids create lots of entries, which leads to data bloat, how to improve? -->


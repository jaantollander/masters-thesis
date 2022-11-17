\newpage

# Collecting usage statistics with Lustre Jobstats
## Overview
In section \ref{lustre-parallel-file-system}, we described Lustre parallel file system and in section \ref{puhti-cluster-at-csc}, we described the Puhti cluster.

We can configure Lustre to collect file system usage statistics with *Lustre Jobstats*, as explained in the section 12.2 of Lustre manual [@lustredocs, sec. 12.2].
Jobstats keeps counters of various statistics of file system-related system calls.

## Setting identifier format
We can enable Jobstats by setting a value for `jobid_name` parameter.
We can specify the format `job_id` with `jobid_name` parameter.
We can use the following format codes.

- `%e` for executable name.
- `%h` for fully-qualified hostname.
- `%H` for short hostname, that is, `%h` such that everything after the first dot (`.`) is removed.
- `%j` for job ID from environment variable specified by `jobid_var` setting.
- `%u` for user ID number.
- `%g` for group ID number.
- `%p` for numeric process ID.

The formatting effects the resolution of the statistics.
Using more formatting codes results in higher resolution but will also accumulate data faster.
We have set parameters `job_id_name="%j:%u:%H"` and `jobid_var=SLURM_JOB_ID` to user Slurm job ID.
Then, we have two `job_id` formats:

`<job>:<uid>:<nodename>`
: with formatting string `"%j:%u:%H"` when `SLURM_JOB_ID` is set. This formatting allows us to separate statistics based on job ID, user ID and nodename.

`<executable>.<uid>`
: with formatting string `"%e.%u"` when `SLURM_JOB_ID` is undefined, such as for Login nodes.

We did not record the group ID, but it could also be useful for identifying if members of a particular group perform problematic file I/O patterns.


## Querying statistics
Each Lustre server keeps counters for all of its targets.
We can fetch the counters and print them in a text format by running `lctl get_param` command with an argument that points to the desired jobstats.
We indicate variables using the syntax `<name>`.

We can query jobstats from MDS as follows:

```sh
lctl get_param mdt.<target>.jobstats
```

The text output is formatted as follows.

```text
mdt.<target>.job_stats=
job_stats:
- job_id: <job_id_1>
  snapshot_time: <snapshot_time_1>
  <operation_1>: <statistics_1>
  <operation_2>: <statistics_2>
  ...
- job_id: <job_id_2>
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
- job_id: <job_id_1>
  snapshot_time: <snapshot_time_1>
  <operation_1>: <statistics_1>
  <operation_2>: <statistics_2>
  ...
- job_id: <job_id_2>
  snapshot_time: <snapshot_time_2>
  <operation_1>: <statistics_1>
  <operation_2>: <statistics_2>
  ...
```

---

The `<target>` indicates the Lustre target of the query.
In Puhti, we have two MDSs with two MDTs each, named `scratch-MDT<index>` and eight OSSs with three OSTs each, named `scratch-OST<index>`.
The prefix `scratch-` indicates that we measure the usage of in the `scratch` storage area.
The `<index>` is four digit integer in hexadecimal format using the characters `0-9a-f` to represent digits.
Indexing starts from zero.
For example, we have targets such as `scratch-MDT0000`, `scratch-OST000f`, and `scratch-OST0023`.

After the `job_stats:` line, we have a list of entries for workloads that have performed file system operations on the target.
Each *entry* is denoted by dash `-` and contains `job_id` identifier, `snapshot_time` and various operations with statistics.

The value in `snapshot_time` field contains a timestamp as a Unix epoch when the statistics of one of the operations was last updated.
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
Each `<operation>` field contains line of `<statistics>` which are formatted as key-value pairs separated by commas and enclosed within curly brackets.

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
That is, Jobstats automatically removes entries with `snapshot_time` older than the cleanup interval.
The default cleanup interval is 10 minutes.

> TODO: there is no certain way of detecting resets, not sure if looking at snapshot times if totally reliable, over estimation is worse than underestimating counter increments, simplicity

We refer to the removal of an entry as *reset*.
In pratice, we detect a *reset* by detecting if any of the counter values decrease which can only happen if the entry.
This method might underestimate increment if counter resets and then does more operations than last count.


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

Due to an bug in Lustre (version 2.12.6 from DDN), we found that some of the identifiers produced by Jobstats were had missing `<job>` or were broken.
We found formatting issues with `job_id` identifiers in the generated data from Lustre Jobstats on the Puhti system.
For example, we found many identifiers without the value in the `job` field on MDS and OSS data from compute nodes.
We believe that this problem is related to `SLURM_JOB_ID` environment variables which could be either no set for some processes, cannot be read in some cases or lost for some other reason.

Furthermore, on the OSS, `job_id`s had issues such as values missing from `uid` and `nodename` fields or fully-qualified hostname instead of the specified short hostname in the `nodename` field.
Even more problematic was that sometimes `job_id` was malformed to the extent that we could not reliably parse information from it.
For example, there were characters in the identifiers missing, overwritten, or duplicated.
We had to discard these entries completely.
We suspect that data race might be causing some of these issues.
[@jobid-atomic]

---

> TODO: add plot of counted job ids

`job` | `uid` | `nodename` | \# entries with user or missing uid | % | \# entries with system uid | %
:-:|:-:|:-:|-:|-:|-:|-:
-|uid|login|55077|24.19|6132|4.81
job|uid|compute|145590|63.93|36909|28.98
-|uid|compute|21037|9.24|84275|66.17
-|uid|puhti|6012|2.64|45|0.04
||||227716||127361|

: \label{tab:mds-entries}
MDS entries


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

: \label{tab:oss-entries}
OSS entries


For example, the tables \ref{tab:mds-entries} and \ref{tab:oss-entries} show the counts of entries of a sample of 113 consecutive 2-minute intervals for MDSs and OSSs separated by normal or missing `uid`s and system `uid`s for different `job_id` compositions.
In the table, "job" indicates that job ID exists, "uid" indicates user ID exists, dash "-" indicates missing value, "login" indicates login node, "compute" indicates compute node, "(q)" indicates fully-qualified nodename and "puhti" indicates node that is not login or compute node.

As a consequence of these issues, data from the same job might be scattered into multiple time series without reliable indicators making it impossible to provide reliable job-specific statistics.
Also, discarded entries lead to some data loss.
The reliability of the counter data does not seem to be affected by this issue.


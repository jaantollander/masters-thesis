\newpage

# Collecting usage statistics with Lustre Jobstats
## Setting identifier format
We can configure Lustre to collect file system usage statistics with *Lustre Jobstats* by setting a value for `jobid_name` parameter, as explained in the section 12.2 of Lustre manual [@lustredocs, sec. 12.2].
Jobstats keeps counters of various statistics of file system-related system calls.
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

Due to an unknown bug in Lustre (version 2.12.6 from DDN), we found that some of the identifiers produced by Jobstats were had missing `<job>` or were broken.
We discuss how to deal with these issues in later sections.


## Querying statistics
Each Lustre server keeps counters for all of its targets.
We can fetch the counters and print them in a text format by running `lctl get_param` command with an argument that points to the desired jobstats.
We indicate variables using the syntax `<name>`.

We can query jobstats from MDS as follows:

```sh
lctl get_param mdt.<source>.jobstats
```

The text output is formatted as follows.

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

Similarly, we can query jobstats from OSS as follows:

```sh
lctl get_param obdfilter.<source>.jobstats
```

The text output is also similar.

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

We can form an unique indentifier over all target by using `<source>` and `<job_id>`.

The value in `snapshot_time` field contains a timestamp as a Unix epoch when the counter was last updated.


## File operations and statistics
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
The samples and sums increase monotonically except then the counter resets.
A counter is reset if none of its values are updated in the duration specified in the configuration, 10 minutes by default.
Units (`<unit>`) are either request (`reqs`), bytes (`bytes`) or microseconds (`usecs`).

Lustre clients may cache certain file operations such as `open`.
That is if `open` is called multiple times with the same arguments Lustre client can serve it from the cache instead of having to request it from MDS.
Thus, cached operations are not counted in the Jobstats, which means, for example, that there can be more `close` than `open` operations because `close` cannot be cached.


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
We believe that this problem is related to `SLURM_JOB_ID` environment variables which could be either no set for some processes, cannot be read in some cases or lost for some other reason.

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


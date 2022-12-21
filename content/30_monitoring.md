\newpage

# Monitoring and analysis
![High-level overview of the monitoring system. Rounded rectangles indicate programs, and arrows indicate data flow. \label{fig:monitoring-system}](figures/lustre-monitor.drawio.svg)

In this section, we describe how our monitoring system works in the Puhti cluster, described in Section \ref{puhti-cluster-at-csc}, and we expand the discussion of the *Lustre Jobstats* mentioned in Section \ref{lustre-parallel-file-system}.
We explain how to enable tracking of file system statistics with Lustre Jobstats, cover the important settings, list which statistics it tracks, how to query them, and the format of the output.

We described how client-server applications work in Section \ref{client-server-application}.
We built the monitoring system as a client-server application, illustrated in Figure \ref{fig:monitoring-system}.
On each Lustre server, a *monitoring client* collects the usage statistics from Lustre Jobstats at regular intervals and sends them to the *ingest server*.
The ingest server processes the data from the monitoring clients and inserts it into the *time series database*.
Then, we can perform queries on the database or dump a batch of data for analysis.
Ideally, we would like to perform continuous analytics on the database as new data arrives, but we leave it for future development.

TODO: 1. attempt

We experienced some problems during the development.
For example, we had a problem directly related to the issues with entry identifiers, covered in Section \ref{entries-and-issues}, 
Because we assumed that all node names would follow the short hostname format, we accidentally parsed the entry identifiers with a short hostname and a fully-qualified hostname as the same.
The mistake led us to identify two different time series as the same, resulting in wrong values when analyzing the statistics.
We patch-fixed it by modifying our parser to disambiguate between the two formats.
However, we lost a fair amount of time and data due to this problem.
Due to the issues we found, we recommend experimenting with the settings, recording large raw dumps of the statistics, and analyzing them offline before building a more complex monitoring system.

The next problem was related to how we computed rates from counter values, which we describe in Section \ref{analyzing-statistics}.
Initially, we computed the difference between two counters online in the monitoring clients and stored them in the database.
This approach made database queries easier since we used a constant interval, so the differences are proportional to the rates.
However, we discovered that if we lose a value, we cannot interpolate it, and the information is lost.
Also, the program design is much more complicated if we compute the rates on the monitoring clients.

TODO: 2. attempt

To solve these problems, we switched to collecting the raw values in the database and computing the rates after we inserted the data.
This approach simplifies the monitoring system, and we can easily interpolate the values for missing intervals.
We can also use a variable interval length if we need.
However, the queries and analysis become more computationally intensive.

As a note from the author, the thesis advisor and system administrators were responsible for enabling Lustre Jobstats, developing the monitoring client and ingest server, installing them on Puhti, and maintaining the database.
We adapted the program code from a GPU monitoring program written in the Go language [@go_language], which used InfluxDB [@influxdb] as a database.
We take the precise design of programs as given and explain them only at a high level.

TODO: thesis work focused on the analysis

TODO: problems in the monitoring effected the analysis, changes into monitoring client and analysis method

<!-- The Lustre monitoring and statistics guide [@lustre-monitoring-guide] presents a general framework and software tools for gathering, processing, storing, and visualizing file system statistics from Lustre. -->


## Entry identifier format
We can enable Jobstats by specifying a formatting string for the *entry identifier* using the `jobid_name` parameter on a Lustre client as explained in the *Lustre Manual* [@docs-lustre, sec. 12.2].
We can configure each Lustre client separately and specify different configurations for different clients.
We can use the following format codes.

- `%e` for *executable name*.
- `%h` for *fully-qualified hostname*.
- `%H` for *short hostname* or *node name*, which removes everything from the fully-qualified hostname after the first dot, including the dot.
- `%j` for *Job ID* from environment variable specified by `jobid_var` setting.
- `%u` for *User ID* number.
- `%g` for *Group ID* number.
- `%p` for *Process ID* number.

The formatting affects the resolution of the statistics.
Using more formatting codes results in higher resolution and leads to a higher rate of data accumulation.

The formatting for Lustre clients on login nodes includes the *Executable name* and User ID.

```
    jobid_name="%e.%u"
```

The formatting for Lustre clients on compute and utility nodes includes Job ID, User ID, and node name.
We set the Job ID to Slurm Job ID.

```
    jobid_name="%j:%u:%H"
    jobid_var=SLURM_JOB_ID
```

We can use the Slurm job ID to retrieve Slurm job information such as project and partition.
For example, the project could also be useful for identifying if members of a particular project perform problematic file I/O patterns.


## Operations and statistics
Each Lustre server keeps counters for all of its targets.
We can fetch the counters and print them in a text format by running the `lctl get_param` command with an argument that points to the desired jobstats.
We can query jobstats from the Lustre server as follows:

```sh
    lctl get_param <server>.<target>.jobstats
```

The text output is formatted as follows.

```text
    <server>.<target>.job_stats=
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

The server (`<server>`) parameter is `mdt` for MDSs and `odbfilter` for OSSs.
The *target* (`<target>`) contains the mount point and name of the Lustre target of the query.
In Puhti, we have two MDSs with two MDTs each, named `scratch-MDT<index>`, and eight OSSs with three OSTs each, named `scratch-OST<index>`.
The `<index>` is a four-digit integer in hexadecimal format using the characters `0-9a-f` to represent digits.
Indexing starts from zero.
For example, we have targets such as `scratch-MDT0000`, `scratch-OST000f`, and `scratch-OST0023`.

After the `job_stats` line, we have a list of entries for workloads that have performed file system operations on the target.
The output denotes each *entry* by dash `-` and contains the entry identifier (`job_id`), *snapshot time* (`snapshot_time`), and various operations with statistics.
The value of snapshot time is a timestamp as a Unix epoch when the statistics of one of the operations are last updated.
*Unix epoch* is the standard way of representing time in Unix systems.
It measures time as the number of seconds elapsed since 00:00:00 UTC on 1 January 1970, excluding leap seconds.

Table \ref{tab:operations} list the operations counted by Jobstats for MDTs and OSTs with the corresponding system calls.
We have omitted some rarely encountered operations from the tables.
Each operation (`<operation>`) contains a line of statistics (`<statistics>`), formatted as key-value pairs separated by commas and enclosed within curly brackets:

```text
    { samples: 0, unit: <unit>, min: 0, max: 0, sum: 0, sumsq: 0 }
```

The samples (`samples`) field counts how many operations the job has requested since Jobstats started the counter.
The fields minimum (`min`), maximum (`max`), sum (`sum`), and the sum of squares (`sumsq`) keep count of these aggregates values.
These fields contain nonnegative integer values.
The samples, sum, and sum of squares increase monotonically except if reset.
Units (`<unit>`) are either requests (`reqs`), bytes (`bytes`), or microseconds (`usecs`).
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
MDT\textcolor{lightgray}{, OST} | **`getattr`** | `stat` | `samples`
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
This table lists all operations tracked by the Jobstats for each Lustre target.
We mentioned system calls in Section \ref{linux-operating-system}.
You can find an explanation of relevant system calls in Appendix \ref{file-system-interface}.
For the details about the `punch` operation, see Appendix \ref{punch-operation}.
The \textcolor{lightgray}{light gray} operation names indicate that the operation field is present in the output, but we did not include it in our analysis.


We found that the counters may report more samples for `close` than `open` operations.
It should not be possible to do more `close` than `open` system calls because a file descriptor returned by open can be closed only once.
We suspect that the Lustre clients cache certain file operations, and Jobstast does not count requests to these operations.
For example, if `open` is called multiple times with the same arguments Lustre client can serve it from the cache instead of having to request it from MDS; thus request is not recorded.


## Entry resets
If Jobstats has not updated the statistics of an entry within the *cleanup interval*, it removes the entry.
That is, if the snapshot time is older than the cleanup interval.
We can specify the cleanup interval in the configuration using the `job_cleanup_interval` parameter.
The default cleanup interval is 10 minutes.

The removal of an entry *resets* the entry.
If a job subsequently performs more operations, we can detect the reset by looking if any of the counter values have decreased.
This method does not detect reset if the new counter value is larger than the old one, but it is uncommon because counter values typically grow large.
In this case, we will underestimate the counter increment when calculating the difference between two counter values.


## Storing time series data
We can use a *time series database* to efficiently store and handle time series data from multiple distinct time series.
*Time series data* has distinctive properties that allow optimizations for storing and querying them.
TimescaleDB documentation [@docs-timescale] characterizes these properties as follows:

1) *time-centric* meaning that records always have a timestamp.
2) *append-only* means that we almost always append new records and rarely update existing data or backfill missing data about old intervals.
3) *recent* new data is typically about recent time intervals.

There are different options for choosing time series databases.
A key differentiation between time series databases is whether they can handle a growing number or a fixed number of distinct time series.
We used *TimescaleDB* because it can handle data with a growing number of distinct time series.
TimescaleDB expands PostgreSQL for storing and analyzing time series data and can scale well to an increasing amount of distinct time series without drastically declining performance.
Initially, we used *InfluxDB* but found out that it did not scale well for our use case.


Field | Type | Value
----|----|----------
`time_series_id` | ID type | Unique identifier for an individual time series.
`timestamp` | Date-time with timezone | Timestamp with UTC timezone.
`<metadata>` | Data type | One or more metadata values related to the time series identifier.
`<data>` | Data type | One or more observed values.

: \label{tab:schema-time-series}
  A record in a time series database consists of a time series identifier, timestamp, metadata, and time series data.


An instance of a time series database consists of *time series tables* with a schema as in Table \ref{tab:schema-time-series}.
The *time series identifier* (`time_series_id`) is an ID type such as an integer type, and the *timestamp* (`timestamp`) is a date-time with *Coordinated Universal Time (UTC)* timezone.
We recommend using UTC instead of local time zones to avoid problems with daylight saving time and date-time instead of Unix epoch because date-times are human-readable.

In our implementation, a time series table is a *TimescaleDB hyper table* with appropriate indices for efficient queries and chunks with a proper time interval for improved performance.
We set a *compression policy* to compress data that is older than a specified time to reduce storage and a *retention policy* for dropping data that is older than a set time to limit data accumulation and for regulatory reasons.
We stored all data on a single time series table.

In the future, we may experiment with separate tables for MDT and OST data to improve performance since they mainly contain different fields.
We would also like to combine the metadata information with Slurm job information.
<!-- It is possible to separate time series data and metadata to reduce data bloat, but it makes queries more complex. -->


## Monitoring client
The monitoring client calls the appropriate command, as explained in Section \ref{operations-and-statistics}, at regular observation intervals to collect statistics.
In the description we present here, we used the time the call was made as the timestamp and stored the snapshot time as a value similar to the statistics.
In practice, our first version used the call time and the second version used the snapshot time as a timestamp.
The downside of using snapshot time as a timestamp is that we lose some information about periods where the job does not perform any operations.

The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and a 10-minute cleanup interval.

The monitoring client parses the target and all entries from the output using *Regular Expressions (Regex)*.
It creates a data structure for all entries with the timestamp, target, parsed entry identifier, snapshot time, and statistics listed in Table \ref{tab:operations}.
An example instance of a data structure using *JavaScript Object Notation (JSON)* looks as follows:

```json
{
  "target": "scratch-OST0001",
  "entry_id": "11317854:17627127:r01c01",
  "timestamp": "2022-11-21T06:02:00.000+00:00",
  "snapshot_time": 1669010520,
  "read": 7754,
  "write": 4284,
  "...": "..."
}
```

The monitoring client must also keep track of previously observed identifiers, concatenation of target and entry identifier (`<target>:<entry_id>`), and the previous observation timestamp.
We must mark the beginning of a time series when we encounter an identifier not present in the previous observation interval.
We mark it by creating a new instance of a data structure with the new target and entry identifier, the previous timestamp, the missing value for snapshot time, and zeros for statistics.
It will be *backfilled* into the database.
For example, if the previous data structure is the first observation, we have the following:

```json
{
  "target": "scratch-OST0001",
  "entry_id": "11317854:17627127:r01c01",
  "timestamp": "2022-11-21T06:00:00.000+00:00",
  "snapshot_time": null,
  "read": 0,
  "write": 0,
  "...": "..."
}
```

Finally, the monitoring client composes a message of the data by listing the individual data structures in a JSON array and sends it to the ingest server via *Hypertext Transfer Protocol (HTTP)*.
Our implementation used the *InfluxDB line protocol* for communication because we designed the code initially for InfluxDB.
Due to the scaling problem, we use TimescaleDB and suggest using JSON for communication instead.


## Ingest server
The ingest server is responsible for maintaining a connection to the database and listening to the messages from the monitoring clients, parsing them, and inserting the data into the database.
Following the previous example, we can parse the values into a structure as follows:

```json
{
  "time_series_id": "scratch-OST0001:11317854:17627127:r01c01",
  "timestamp": "2022-11-21T06:02:00.000+00:00",
  "target": "scratch-OST0001",
  "job_id": 11317854,
  "user_id": 17627127,
  "node_name": "r01c01",
  "executable_name": null,
  "snapshot_time": 1669010520,
  "read": 7754,
  "write": 4284,
  "...": "..."
}
```

We mark missing values as null.
Then, we can convert this structure into an insert statement and send it to a time series table in the database with similar column names.
Optionally, we can use the concatenated string of target and entry identifier (`<target>:<entry_id>`) as the time series identifier.
It is optional since we can identify individual time series from the metadata alone.
However, it might reduce ambiguity about identifying an individual time series.

In our implementation, we parsed the metadata on the monitoring clients rather than in the ingest server and did not explicitly set a time series identifier.
Instead, we identified different time series as distinct tuples of the target, node name, job ID, and user ID.
For login nodes, which do not have a job ID, we generated a synthetic job ID using the executable name and user ID values.
Also, we created a synthetic job ID for other entries for which it was missing.
We dropped entries that did not conform to the entry identifier format we had set, as described in Section \ref{entry-identifier-format}.


## Analyzing statistics
TODO: describe analysis at high level, reference to Appendix

Compute rates from counter values from Jobstats in as a stream.


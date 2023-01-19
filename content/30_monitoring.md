\clearpage

# Monitoring and analysis
![
A high-level overview of the monitoring system and analysis.
Rounded rectangles indicate programs, and arrows indicate data flow.
\label{fig:monitoring-system}
](figures/lustre-monitor.drawio.svg)

<!-- The Section \ref{puhti-cluster-at-csc} described the Puhti cluster. -->
This section explains how our monitoring system works in the Puhti cluster and how we analyze the data.
We explain how to collect file system usage statistics with *Lustre Jobstats*, mentioned in Section \ref{lustre-parallel-file-system}.
Subsection \ref{entry-identifier-format} covers the settings we used for the entry identifiers for collecting fine-grained statistics.
In Subsection \ref{file-system-statistics}, we explain the different file system operations and statistics for them that we can track, how to query them, and the output format.
We explain how the statistics reset in Subsection \ref{entry-resets}.

Subsection \ref{computing-rates} explain how to compute average file system usage rates from the statistics.
We suspect that high total file system usage rates can cause congestion in the file system.
Fine-grained statistics allow us to break down the total rate into its components.
Then, we can analyze the components and identify the components with the highest rates.

TODO: explain Subsection \ref{backfilling-initial-entries}

We described how client-server applications work in Section \ref{client-server-application}.
We built the monitoring system as a client-server application, consisting of a Monitoring client, an Ingest server, and a Time series database, illustrated in Figure \ref{fig:monitoring-system}.
The statistics we collect from Jobstats form multiple time series.
We explain how we store time series data in the *time series database* in Subsection \ref{storing-time-series-data}.
In Subsection \ref{monitoring-client}, we explain how a *monitoring client* collects the usage statistics from Lustre Jobstats on each Lustre server and sends them to the *ingest server*.
Due to various issues, we had to modify the monitoring client during the thesis.
These changes affected the analysis and required significant changes in the analysis code and methods.
We explain the initial and modified versions of the monitoring client.
Subsection \ref{ingest-server} explains how the ingest server processes the data from the monitoring clients and inserts it into the time series database.

The thesis work focused on the analysis and visualization parts.
We explain how we analyzed batches of time series data in Subsection \ref{analyzing-statistics}.
In the future, we would like to compute the rates on the database as new data arrives and perform real-time analytics on them.

The thesis advisor and system administrators were responsible for enabling Lustre Jobstats, developing the monitoring client and ingest server, installing them on Puhti, and maintaining the database.
We adapted the Monitoring client and Ingest server codes from a GPU monitoring program written in the Go language [@go_language], which used InfluxDB [@influxdb] as a database.
We changed the database to TimescaleDB.
We take the precise design of programs as given and explain them only at a high level.


## Entry identifier format
We can enable Jobstats by specifying a formatting string for the *entry identifier* using the `jobid_name` parameter on a Lustre client as explained in the *Lustre Manual* [@docs-lustre, sec. 12.2].
We can configure each Lustre client separately and specify different configurations for different clients.
We can use the following format codes.

- `%e` for *executable name*.
- `%h` for *fully-qualified hostname*.
- `%H` for *short hostname* or *node name*, which removes everything from the fully-qualified hostname after the first dot, including the dot.
- `%j` for *job ID* from environment variable specified by `jobid_var` setting.
- `%u` for *user ID* number.
- `%g` for *group ID* number.
- `%p` for *process ID* number.

The formatting affects the resolution of the statistics.
Using more formatting codes results in higher resolution and leads to a higher rate of data accumulation.

The formatting for Lustre clients on login nodes includes the executable name and user ID.

```
    jobid_name="%e.%u"
```

The formatting for Lustre clients on compute and utility nodes includes job ID, user ID, and node name.
We set the job ID to Slurm job ID.

```
    jobid_name="%j:%u:%H"
    jobid_var=SLURM_JOB_ID
```

For Puhti, we listed the node names in Table \ref{tab:node-names}.


## File system statistics
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
The *target* (`<target>`) contains the name of the Lustre target of the query.
For Puhti, we listed them in Table \ref{tab:mdt-mds}.
<!--
In Puhti, we have two MDSs with two MDTs each, named `scratch-MDT<index>`, and eight OSSs with three OSTs each, named `scratch-OST<index>`.
The `<index>` is a four-digit integer in hexadecimal format using the characters `0-9a-f` to represent digits.
Indexing starts from zero.
For example, we have targets such as `scratch-MDT0000`, `scratch-OST000f`, and `scratch-OST0017`.
-->


After the `job_stats` line, we have a list of entries for workloads that have performed file system operations on the target.
The output denotes each *entry* by dash `-` and contains the entry identifier (`job_id`), *snapshot time* (`snapshot_time`), and various operations with statistics.
The value of snapshot time is a timestamp as a Unix epoch when the statistics of one of the operations are last updated.
*Unix epoch* is the standard way of representing time in Unix systems.
It measures time as the number of seconds elapsed since 00:00:00 UTC on 1 January 1970, excluding leap seconds.

In Table \ref{tab:operations}, we list the MDT and OST operations for which Jobstats keeps statistics.
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


Targets | Lustre file system operation | Linux system call | Parsed statistics
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
The \textcolor{lightgray}{light gray} operation names indicate that the operation field is present in the output, but the values were always zero. Thus, we did not include them in our analysis.
The tables contain the corresponding system calls for each Lustre operation.
We explain each system call in Appendix \ref{file-system-interface}.

<!-- TODO: move explanations of each Lustre file system operation from Appendix to the table -->


## Entry resets
If Jobstats has not updated the statistics of an entry within the *cleanup interval*, it removes the entry, referred to as *reset*.
That is if the snapshot time is older than the cleanup interval.
We can specify the cleanup interval in the configuration using the `job_cleanup_interval` parameter.
The default cleanup interval is 10 minutes.

We *detect the resets* by observing if any counter-values have decreased.
This method does not detect reset if the new counter value is larger than the old one, but it is uncommon because counter values typically grow large.
We will underestimate the counter increment in this case when calculating the difference between two counter values.


## Computing rates
We can calculate a *rate* during an interval from two counter values by dividing the difference between the counter values by the interval length.
We treat the previous counter value as zero if we detect a reset.
For Jobstats, a rate during an interval tells us how many operations, on average, happen per time unit during an interval.
For example, if the previous counter of write operations for a job is $v_1=1000$ at time $t_1=0$ seconds, and the current value is $v_2=2000$ at time $t_2=120$ seconds, it performed $v_2-v_1=1000$ write operations during the interval of $t_2-t_1=120$ seconds.
Therefore, on average, the job performed $1000/120\approx 8.33$ write operations per second during the interval.
We explain theoretical details about computing rates in Appendix \ref{computing-and-aggregating-rates}.


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
The monitoring client calls the appropriate command, as explained in Section \ref{file-system-statistics}, at regular observation intervals to collect statistics.
The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and a 10-minute cleanup interval.
In the future, we could reduce the observation interval to 1-minute.

<!-- computing differences on the fly -->
Initially, we computed the difference between the two counters on the monitoring clients and stored them in the database.
Since we used a constant interval, the differences were proportional to the rates explained in Section \ref{computing-rates}, making database queries easy and fast.
Also, computing the differences in the monitoring clients makes the design more complex and error-prone.

<!-- parsing the entry identifier -->
Also, we had a problem with malformed entry identifiers, discussed later in Section \ref{entries-and-issues}.
Due to the bug, some node names were in the fully-qualified format instead of the short hostname format.
Because we assumed that all node names would follow the short hostname format, we parsed the metadata from the entry identifiers with a short hostname and a fully-qualified hostname as the same.
The mistake made us identify two different time series as the same, resulting in wrong values when computing rates.
We fixed it by modifying our parser to disambiguate between the two formats.
Due to the issues we found, we recommend experimenting with the settings, recording large raw dumps of the statistics, and analyzing them offline before building a more complex monitoring system.

<!-- recording the raw counters -->
To solve and identify these problems, we switched to collecting the counter values in the database and computing the rates afterward.
This approach simplifies the monitoring system and supports variable interval lengths.
However, the approach makes queries and analysis more computationally intensive.

Our implementation used the *InfluxDB line protocol* for communication because we designed the code initially for InfluxDB.
Due to the scaling problem, we use TimescaleDB and suggest using a more efficient line protocol for communication instead.
Next, we describe the monitoring client and the message structure using JSON.

<!-- In the description we present here, we used the time the call was made as the timestamp and stored the snapshot time as a value similar to the statistics. -->
The monitoring client parses the target and all entries from the output using *Regular Expressions (Regex)*.
It creates a data structure for all entries with the timestamp, target, parsed entry identifier, snapshot time, and statistics listed in Table \ref{tab:operations}.
An example instance of a data structure using *JavaScript Object Notation (JSON)* looks as follows:

```json
{
  "timestamp": "2022-11-21T06:02:00.000+00:00",
  "entry_id": "11317854:17627127:r01c01",
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

Finally, the monitoring client composes a message of the data by listing the individual data structures and sends it to the ingest server via *Hypertext Transfer Protocol (HTTP)*.


## Backfilling initial entries
<!-- TODO: first version had to keep track -->
We must manually add an initial entry filled with zeros when a new entry appears, or old entry resets in Jobstats.
Otherwise, we lose data from the first observation interval.
During this thesis, we backfilled the initial entries during the analysis.
In the future, we should backfill them into the database to keep the analysis simpler.

To detect initial entries, the monitoring client must keep track of previously observed identifiers, concatenation of target and entry identifier (`<target>:<entry_id>`), and the previous observation timestamp.
When the client encounters an identifier not present in the previous observation interval, it creates a new instance of a data structure with the new target and entry identifier, the previous timestamp, the missing value for snapshot time, and zeros for statistics.
For example, if the previous data structure is the first observation, we have the following:

```json
{
  "timestamp": "2022-11-21T06:00:00.000+00:00",
  "target": "scratch-OST0001",
  "entry_id": "11317854:17627127:r01c01",
  "job_id": 11317854,
  "user_id": 17627127,
  "node_name": "r01c01",
  "executable_name": null,
  "snapshot_time": null,
  "read": 0,
  "write": 0,
  "...": "..."
}
```

The monitoring client sends this to the ingest server as explained in Section \ref{monitoring-client}.


## Ingest server
The ingest server is responsible for maintaining a connection to the database, listening to the monitoring clients' messages, and parsing them.
The server creates an insert statement for every message and sends it into the time series database to add the data.

We did not explicitly set a time series identifier.
Instead, we identified different time series as distinct tuples of the target, node name, job ID, and user ID.
For login nodes, which do not have a job ID, we generated a synthetic job ID using the executable name and user ID values.
Also, we created a synthetic job ID for other entries for which it was missing.
We dropped other entries that did not conform to the entry identifier format we had set, as described in Section \ref{entry-identifier-format}.

We could use the concatenated target and entry identifier string as the time series identifier (`<target>:<entry_id>`).
It is optional since we can identify individual time series from the metadata alone.
However, it might reduce ambiguity about identifying an individual time series.


## Analyzing statistics
We analyzed batches of the raw counter data using the Julia language [@julia_fresh_approach; @julia_language].
We dumped data from the database into Parquet files, such that each file contained data from one day, which limited the file size to manageable on a local computer.
We used Parquet.jl package to parse the data, which we converted into a data frame using DataFrames.jl [@julia_dataframes].
We computed rates from the counter values for each time series and performed explorative data analysis on the rates, such as computing sums over different subsets and computing densities.
We visualized them using Plots.jl [@julia_plots] with PlotlyJS backend for interactive graphics.
We show many of the visualizations in Section \ref{results}.
We describe the theoretical aspects of computing rates from counters, manipulating rates, and aggregating them in Appendix \ref{computing-and-aggregating-rates}.
The aggregation methods include computing a sum and density.

<!-- TODO: we used snapshot time as the timestamp and inferred the beginning of the time series -->


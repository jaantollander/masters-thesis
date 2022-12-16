\newpage

# Monitoring system
![High-level overview of the monitoring system. Rounded rectangles indicate programs, and arrows indicate data flow. \label{fig:monitoring-system}](figures/lustre-monitor.drawio.svg)

In this section, we describe how our monitoring system works in the context of the Puhti cluster, described in Section \ref{puhti-cluster-at-csc}, and we expand the discussion of the *Lustre Jobstats* mentioned in Section \ref{lustre-parallel-file-system}.
We explain how to enable tracking of file system statistics with Lustre Jobstats, cover the important settings, list which statistics it tracks, how to query them, and the format of the output.

We built the monitoring system using the client-server architecture as seen in Figure \ref{fig:monitoring-system}.
On each Lustre server, a *monitoring client* collects the usage statistics from Lustre Jobstats at regular intervals and sends them to the *ingest server*.
The ingest server processes the data from the monitoring clients and inserts it into the *time series database*.
Then, we can perform queries on the database or dump a batch of data for analysis.
Ideally, we would like to perform continuous analytics on the database as new data arrives, but we leave it for future development.

We experienced some problems during the development.
For example, we had a problem directly related to the issues with entry identifiers, covered in Section \ref{issues-with-entry-identifiers}, 
Because we assumed that all nodenames would follow the short hostname format, we accidentally parsed the entry identifiers with a short hostname and a fully-qualified hostname as the same.
The mistake led us to identify two different time series as the same, resulting in wrong values when analyzing the statistics.
We patch-fixed it by modifying our parser to disambiguate between the two formats.
However, we lost a fair amount of time and data due to this problem.
Due to the issues we found, we recommend experimenting with the settings, recording large raw dumps of the statistics, and analyzing them offline before building a more complex monitoring system.

The next problem was related to how we computed rates from counter values, which we describe in Section \ref{analyzing-statistics}.
Initially, we computed the difference between two counters online in the monitoring clients and stored them in the database.
This approach made database queries easier since we used a constant interval, so the differences are proportional to the rates.
However, we discovered that if we lose a value, we cannot interpolate it, and the information is lost.
Also, the program design is much more complicated if we compute the rates on the monitoring clients.

To solve these problems, we switched to collecting the raw values in the database and computing the rates after we inserted the data.
This approach simplifies the monitoring system, and we can easily interpolate the values for missing intervals.
We can also use a variable interval length if we need.

As a note from the author, the thesis advisor and system administrators were responsible for enabling Lustre Jobstats, developing the monitoring client and ingest server, installing them on Puhti, and maintaining the database.
We adapted the program code from a GPU monitoring program written in the Go language, which used InfluxDB [@influxdb] as a database.
We take the precise design of programs as given and explain them only at a high level.

<!-- The Lustre monitoring and statistics guide [@lustre-monitoring-guide] presents a general framework and software tools for gathering, processing, storing, and visualizing file system statistics from Lustre. -->


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


## Storing time series data
Field | Type | Value
----|----|----------
`time_series_id` | UUID | Identifier for an individual time series.
`timestamp` | Datetime with timezone | Timestamp with UTC timezone.
`<field>` | Data type | One or more observed values.

: \label{tab:schema-time-series}
  Each *record of time series data* consists of an time series identifier and timestamp with one or more values of the observations and is.


Field | Type | Value
----|----|----------
`time_series_id` | UUID | Identifier for an individual time series.
`<field>` | Data type | One or more metadata values related to the time series identifier.

: \label{tab:schema-metadata}
  Each *record of metadata* consists of the times series identifier and one or more metadata values.


We can use a *time series database* to efficiently store and handle time series data from multiple distinct time series.
*Time series data* has distinctive properties that allow optimizations for storing and querying them.
TimescaleDB documentation [@docs-timescale] characterizes these properties as:

1) *time-centric* meaning that records always have a timestamp.
2) *append-only* meaning that we almost always append new records and rarely update existing data or backfill missing data about old intervals.
3) *recent* new data is typically about recent time intervals.

There are different options for choosing a time series databases.
One key differentiation between time series databases is whether they are built to handle fixed or growing amount of distinct time series.
Since we handle data that has a growing number of distinct time series we chose *TimescaleDB*.
TimescaleDB expands PostgreSQL for storing and analyzing time series data and can scale well to an increasing amount of distict time series without its performance suffering drastically.
Initially, we used *InfluxDB*, but found out that it did not scale well for our use case.

An instance of time series database consist of one or more *time series tables* with schema as in Table \ref{tab:schema-time-series} and optional *metadata table* with schema as in Table \ref{tab:schema-metadata}.
A separate metadata table reduces data bloat and makes it easier to alter its schema later.
We can join the metadata table and time series table during queries.

For the *time series identifier* (`time_series_id`), we can use a *Universally Unique Identifier (UUID)* which has the benefit of being standardized and has explicit support for namespaces.

For the *timestamp* (`timestamp`), we use datetime with *Coordinated Universal Time (UTC)* timezone instead of local timezones to avoid problems with daylight saving time.
We recommend datetime instead of Unix epoch, because datetimes are human readable.

The time series table is a *TimescaleDB hypertable* with *indices* for efficient queries, *chunked* by a chosen time interval for improved performance, a *compression policy* to compress data that is older than specified time to reduce storage, and a *retention policy* for dropping data that is older than specified time to limit data accumulation or for privacy and regulatory reasons.
The metadata table is regular PostgreSQL table.

In our implementation, we stored everything on a single table.
In future implementations, we should use a separate metadata table and time series tables for MDT and OST data since they mainly contain different fields.
Also, we could combine the metadata infromation with Slurm job information.


## Monitoring client
The monitoring client calls the appropriate command (`lctl get_param`) as explained in Section \ref{operations-and-statistics}, at regular observation intervals to collect statistics.
In the description that we present here, we used the the time at which the call was made as the timestamp and store the snapshot time as value similar to the statistics.
In practise, our first version used the call time and second version used the snapshot time as timestamp.
The downside of using snapshot time as timestamp is that we lose some information about periods where the job does not perform any operations.

The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and 10-minute cleanup interval.

Monitoring client parses the target and all entries from the output using *Regular Expressions (Regex)*.
For all entries, it creates a data structure with the timestamp, target, and parsed entry identifier, snapshot time and statistics listed on Table \ref{tab:operations}.
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
If we encounter an identifier that was not present in the previous observation interval, we must create a new instance of an data structure with the new target and entry identifier, the previous timestamp, missing value for snapshot time and zeros for statistics to mark the beginning of time series.
It will be *backfilled* to the database.
For example, if the previous data structure is the first observation, we have:

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
Our implementation actually used the *InfluxDB line protocol* for communication because we designed the code initially for InfluxDB.
Due to the scaling problem, we switched to TimescaleDB and suggest using JSON for communication instead.


## Ingest server
The ingest server is responsible for maintaining a connection to the database and listening to the messages from the monitoring clients, parsing them and inserts the data to the database.

In our implementation we did not use a time series identifier explicitly.
Instead we identified different time series as distict tuples of target, nodename, job ID, and user ID.
For login nodes, which do not have a job ID, we generated synthetic job ID using the executable name and user ID values.
We also parsed the values on the monitoring clients, rather than in the ingest server.
However, a time series identifier is easier to use in database queries, reduces ambiguity about how to identify an individual time series and allows separating the metadata and time series data.

For future implementations we should use a time series identifier.
We can generate the time series identifier as UUID from the concatenated string of target and entry identifier (`<target>:<entry_id>`) with a randomly generated UUID as *namespace* associated with the formatting of the target and entry identifier strings.
If the formatting changes, we should change the namespace to avoid collision with time series identifiers.
If the namespace is kept secret, the UUID also anonymizes the metadata values associated with time series data.
For example, we can generate a namespace as follows:

```sh
uuidgen --random
```

```
2e79b8a1-c4fc-45ba-9023-d16fdce6e3fe
```

Then, we can generate the time series identifier using the namespace and concatenated string of target and entry identifier.

```sh
uuidgen --sha1 \
    --namespace="2e79b8a1-c4fc-45ba-9023-d16fdce6e3fe" \
    --name="scratch-OST0001:11317854:17627127:r01c01"
```

```
af854063-c381-585f-b551-ce0b6c4440a3
```

Now, we can separate the ingested data into *time series structure* and *metadata structure*.
We should append the time series structure to the appropriate time series table.

```json
{
  "time_series_id": "af854063-c381-585f-b551-ce0b6c4440a3",
  "timestamp": "2022-11-21T06:02:00.000+00:00",
  "snapshot_time": 1669010520,
  "read": 7754,
  "write": 4284,
  "...": "..."
}
```

Metadata structure contains the parsed metadata fields or null if the value is missing.
We need to parse and update metadata only if it does not already exists in the metadata table.

```json
{
  "time_series_id": "af854063-c381-585f-b551-ce0b6c4440a3",
  "target": "scratch-OST0001",
  "entry_id": "11317854:17627127:r01c01",
  "job_id": 11317854,
  "user_id": 17627127,
  "nodename": "r01c01",
  "executable": null
}
```

We can convert these structures into appropriate insert statements and send them to the database with columns named similarly as in the structures.


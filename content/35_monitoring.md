\newpage

# Monitoring workflow
![
The pipeline for monitoring and recording the statistics consists of multiple instances of a monitoring daemon and a single instance of an ingest daemon, and a time series database.
*Daemon* is a program that runs in the background.
We installed a monitoring daemon to each Lustre server, and an ingest daemon and a database to a utility node on Puhti.
\label{fig:monitoring-workflow}
](figures/lustre-monitor.drawio.svg)



## Time series database
*Time series database* is a database that is optimized for storing and querying time series data.
We used TimescaleDB which expands PostgreSQL for storing and analyzing time series data.
They characterize time series data as follows:
[@timescaledocs]

*Time-centric*:
: Data records always have a timestamp.

*Append-only*:
: Data is almost solely append-only (INSERTs).

*Recent*:
: New data is typically about recent time intervals, and we more rarely make updates or backfill missing data about old intervals.

TimescaleDB can efficiently store time series data and comes with built-in hyperfunction for aggregating metrics from time series data such as counter values.


Field | Type | Value
---|---|----------
`identifier` | `BIGINT` | Hash of the tuple `(<target>, <job_id>)`.
`target` | `TEXT` | `<target>` value.
`job` | `BIGINT` | `<job>` value if exists, otherwise `NULL`.
`uid` | `BIGINT` | `<uid>` value if exists, otherwise `NULL`.
`nodename` | `TEXT` | `<nodename>` value if exists, `login` for login nodes, otherwise an empty string.
`executable` | `TEXT` | `<executable>` value if exists, otherwise an empty string.

: \label{tab:metadata-schema}
Schema of metadata table.
Mapping between the time series identifier and the metadata.
The `identifier` uniquely identifies a row.


Field | Type | Value
---|---|----------
`timestamp` | `TIMESTAMPTZ` | Timestamp of the query time as datetime type with Universal Coordinated Time (UTC) timezone.
`identifier` | `BIGINT` | Hash of the tuple `(target, job_id)`.
`<operation_*>` | `DOUBLE` | The `sum` value for the `read_bytes` and `write_bytes` operations and `samples` value for the other operations from the `<statistics_*>` key-value pairs.

: \label{tab:time-series-schema}
Schema of the time series table.
Wide-table model, values for multiple operations in one record.
The tuple `(timestamp, identifier)` uniquely identifies a row.

Timescale can join the metadata table and time series table during queries.
We need to cast counts to double precision in order to perform analysis on the database.


## Monitoring and ingest daemons
Each monitoring daemon calls the appropriate `lctl get_param` command at regular observation intervals to collect statistics.
Then, it parses the `<target>` and the output of each entry (a line beginning with dash `-`) into a data structure.

The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and 10-minute cleanup interval.

The monitoring daemons send these data structures to the ingest daemon in batches.
The ingest daemon listens to the requests from the monitoring daemons and stores the data in a time series database such that each instance of the data structure represents a single row.

We need to keep track of previous observed identifiers and previous timestamp.
If we encounter a new identifier, we should also *backfill* a record with the new identifier, the previous timestamp and zeros for operation values to mark the beginning of time series.


## Querying the database
Querying the database, identify workloads performing I/O patterns that are potentially harmful

* select a time interval and desired identifiers
* group by `identifier` to form multiple time series
* compute rates of change for each time series


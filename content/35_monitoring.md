\newpage

# Monitoring workflow
![Monitoring workflow \label{fig:monitoring-workflow}](figures/lustre-monitor.drawio.svg)

The pipeline for monitoring and recording the statistics consists of multiple instances of a monitoring daemon and a single instance of an ingest daemon, and a time series database.
*Daemon* is a program that runs in the background.
We installed a monitoring daemon to each Lustre server, and an ingest daemon and a database to a utility node on Puhti.


## Time series database
*Time series database* is a database that is optimized for storing and querying time series data.
We used TimescaleDB which expands PostgreSQL for time series and analytics.
[@timescaledocs]

TODO: explain the characteristics of time series data and benefits of time series database from timescale docs

Field | Type | Value
---|--|----------
`identifier` | integer | Primary key. Hash of the tuple `(<target>, <job_id>)`.
`target` | string | `<target>` value.
`job` | integer | `<job>` value if exists, otherwise `NULL`.
`uid` | integer | `<uid>` value if exists, otherwise `NULL`.
`nodename` | string | `<nodename>` value if exists, `login` for login nodes, otherwise an empty string.
`executable` | string | `<executable>` value if exists, otherwise an empty string.

: \label{tab:metadata-schema}
Schema of metadata table.
Mapping between the time series identifier and the metadata.


Field | Type | Value
---|--|----------
`timestamp` | datetime | Primary key. Timestamp of the query time as datetime type with Universal Coordinated Time (UTC) timezone.
`identifier` | integer | Primary key. Hash of the tuple `(target, job_id)`.
`<operation_*>` | double | The `sum` value for the `read_bytes` and `write_bytes` operations and `samples` value for the other operations from the `<statistics_*>` key-value pairs.

: \label{tab:time-series-schema}
Schema of the time series table.
Wide-table model.

Timescale can join the metadata table and time series table during queries.
We need to cast counts to double precision in order to perform analysis on the database.


## Monitoring and ingest daemons
Each monitoring daemon calls the appropriate `lctl get_param` command at regular observation intervals to collect statistics.
Then, it parses the `<target>` and the output of each entry (a line beginning with dash `-`) into a data structure as explained in table \ref{tab:data-structure}.
The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and 10-minute cleanup interval.


The monitoring daemons send these data structures to the ingest daemon in batches.
The ingest daemon listens to the requests from the monitoring daemons and stores the data in a time series database such that each instance of the data structure represents a single row.

TODO: backfill initial counters

We need to keep track of previous observed identifiers and previous timestamp.
If we encounter a new identifier, we should also append a data structure with the previous timestamp and zeros for operation values to mark the beginning of time series.


## Querying the database
Querying the database, identify workloads performing I/O patterns that are potentially harmful

* select a time interval and desired identifiers
* group by `identifier` to form multiple time series
* compute rates of change for each time series


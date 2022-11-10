\newpage

# Monitoring workflow
\label{sec:monitoring-workflow}

![](figures/lustre-monitor.drawio.svg)

The pipeline for monitoring and recording the statistics consists of multiple instances of a monitoring daemon and a single instance of an ingest daemon, and a time series database.
*Daemon* is a program that runs in the background.
We installed a monitoring daemon to each Lustre server, and an ingest daemon and a database to a utility node on Puhti.


## Time series database
\label{sec:time-series-database}

*Time series database* is a database that is optimized for storing and querying time series data.
We used a PostgreSQL database with a Timescale extension.
[@timescaledocs]

- TODO: explain the characteristics of time series data and benefits of time series database from timescale docs


## Monitoring and ingest daemons
\label{sec:monitoring-and-ingest-daemons}

Each monitoring daemon calls the appropriate `lctl get_param` command at regular observation intervals to collect statistics.
Then, it parses the `<target>` and the output of each entry (a line beginning with dash `-`) into a data structure as explained in table \ref{tab:data-structure}.
The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute interval and 10-minute cleanup interval.

Field | Type | Value
---|-|---------
`timestamp` | integer | Timestamp of the query time as Universal Coordinated Time (UTC).
`snapshot_time` | integer | Parsed from `<snapshot_time>` value.
`job` | integer | Parsed from `<job_id>` value. We generate synthetic identifiers for missing `job` values.
`uid` | integer | Parsed from `<job_id>` value.
`nodename` | string | Parsed from `<job_id>` value. For login nodes we set it to `login`.
`target` | string | Parsed from `<target>` value.
`executable` | string | Parsed from `<executable>` value. Empty string if doesn't exist.
`<operation_*>` | integer | We parse the `sum` value for the `read_bytes` and `write_bytes` operations and `samples` value for the other operations from the `<statistics_*>` key-value pairs.

: \label{tab:data-structure}
Data structure of parsed Jobstats entry.

The monitoring daemons send these data structures to the ingest daemon in batches.
The ingest daemon listens to the requests from the monitoring daemons and stores the data in a time series database such that each instance of the data structure represents a single row.

We need to keep track of previous observed identifiers and previous timestamp.
If we encounter a new identifier, we should also append a data structure with the previous timestamp and zeros for operation values to mark the beginning of time series.


## Querying the database
\label{sec:querying-the-database}

Querying the database

* select a time interval and desired identifiers
* group by `(job, uid, nodename, target)` to form multiple time series
* compute rates of change for each time series


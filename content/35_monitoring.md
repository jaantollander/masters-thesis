\newpage

# Monitoring workflow
## Overview


## Storing time series data
Field | Type | Value
---|----|----------
`identifier` | `UUID NOT NULL` | Universally Unique Identifier of an individual time series
`timestamp` | `TIMESTAMPTZ NOT NULL` | Timestamp with UTC timezone.
`<value>` | `<type>` | One or more observed values.

: \label{tab:schema-time-series}
  Each *record of time series data* consists of an unique identifier and timestamp with one or more values or the observations.


Field | Type | Value
---|----|----------
`identifier` | `UUID NOT NULL` | Universally Unique Identifier of an individual time series
`<value>` | `<type>` | One or more metadata values related to the identifier.

: \label{tab:schema-metadata}
  Each *record of metadata* for each unique identifier consists of the identifier and one or more metadata values.


Time series data has distinctive properties that allow optimizations for storing and querying them.
*Time series database* is a database that is built around these optimizations to effcienly handle time series data.
For example, we used *TimescaleDB* which expands PostgreSQL for storing and analyzing time series data.
TimescaleDB documentation characterize the properties of time series data as follows:
[@timescaledocs]

*Time-centric*:
: Data records always have a timestamp.

*Append-only*:
: Data is almost solely append-only.

*Recent*:
: New data is typically about recent time intervals, and we more rarely make updates or backfill missing data about old intervals.

An instance of time series database consist of *time series table* with schema as in table \ref{tab:schema-time-series} and optional *metadata table* with schema as in table \ref{tab:schema-metadata}.
The time series table is a *TimescaleDB hypertable* with *indices* for efficient queries, *chunks* by chosen time interval for improved performance, a *compression policy* to compress data that is older than specified time to reduce storage, and a *retention policy* for dropping data that is older than specified time to limit data accumulation or for privacy and regulatory reasons.
The metadata table is regular PostgreSQL table.
We can join the metadata table and time series table during queries.


## Database schema and queries
Field | Type | Value
---|---|----------
`identifier` | `UUID` |
`timestamp` | `TIMESTAMPTZ` | Timestamp of the query time with UTC timezone.
`<operation_*>` | `DOUBLE` | The `sum` value for the `read_bytes` and `write_bytes` operations and `samples` value for the other operations from the `<statistics_*>` key-value pairs.

: \label{tab:schema-jobstats-time-series}
Schema of the time series table.
Wide-table model, values for multiple operations in one record.
The tuple `(timestamp, identifier)` uniquely identifies a row.


Field | Type | Value
---|---|----------
`identifier` | `UUID` |
`target` | `TEXT` | `<target>` value.
`job` | `BIGINT` | `<job>` value if exists, otherwise `NULL`.
`uid` | `BIGINT` | `<uid>` value if exists, otherwise `NULL`.
`nodename` | `TEXT` | `<nodename>` value if exists, `login` for login nodes, otherwise an empty string.
`executable` | `TEXT` | `<executable>` value if exists, otherwise an empty string.

: \label{tab:schema-jobstats-metadata}
Schema of metadata table.
Mapping between the time series identifier and the metadata.
The `identifier` uniquely identifies a row.


The `identifier` is UUID value of computer from the string `<target><job_id>`.

* indices by `(identifier, timestamp DESC)` for efficient group by and time interval constraints
* chunk by `(identifier, timestamp)`
* counter aggregates
* We need to cast counts to double precision in order to perform analysis on the database.

Querying the database

* select a time interval and desired identifiers
* group by `identifier` to form multiple time series
* compute rates of change for each time series

See appendix \ref{time-series-database} for conrete examples. 


## Monitoring and ingest daemons
![
The pipeline for monitoring and recording the statistics consists of multiple instances of a monitoring daemon and a single instance of an ingest daemon, and a time series database.
*Daemon* is a program that runs in the background.
We installed a monitoring daemon to each Lustre server, and an ingest daemon and a database to a utility node on Puhti.
\label{fig:monitoring-workflow}
](figures/lustre-monitor.drawio.svg)

Each monitoring daemon calls the appropriate `lctl get_param` command at regular observation intervals to collect statistics.
Then, it parses the `<target>` and the output of each entry (a line beginning with dash `-`) into a data structure.

The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and 10-minute cleanup interval.

The monitoring daemons send these data structures to the ingest daemon in batches.
The ingest daemon listens to the requests from the monitoring daemons and stores the data in a time series database such that each instance of the data structure represents a single row.

We need to keep track of previous observed identifiers and previous timestamp.
If we encounter a new identifier, we should also *backfill* a record with the new identifier, the previous timestamp and zeros for operation values to mark the beginning of time series.


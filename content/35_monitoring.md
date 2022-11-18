\newpage

# Monitoring system
## Overview
![
The pipeline for monitoring and recording the statistics is built using the client-server architecture.
It consists of multiple monitoring clients and an ingest server connected to a time series database.
On each Lustre server, a monitoring client queries the jobstats on regular intervals and sends the data to the ingest server that inserts them to a time series database.
\label{fig:monitoring-workflow}
](figures/lustre-monitor.drawio.svg)


## Storing time series data
Field | Type | Value
---|----|----------
`identifier` | UUID | Universally Unique Identifier of an individual time series.
`timestamp` | Datetime with timezone | Timestamp with UTC timezone.
`<field>` | Data type | One or more observed values.

: \label{tab:schema-time-series}
  Each *record of time series data* consists of an `identifier` and `timestamp` with one or more values of the observations and is uniquely identified by the tuple of values `(identifier, timestamp)`.


Field | Type | Value
---|----|----------
`identifier` | UUID | Universally Unique Identifier of an individual time series.
`<field>` | Data type | One or more metadata values related to the identifier.

: \label{tab:schema-metadata}
  Each *record of metadata* consists of the `identifier` and one or more metadata values and is uniquely identified by the `identifier`.


Time series data has distinctive properties that allow optimizations for storing and querying them.
*Time series database* is a database that is built around these optimizations to effcienly handle time series data.
We used *TimescaleDB* (version ???) which expands PostgreSQL for storing and analyzing time series data.
TimescaleDB documentation characterize the properties of time series data as follows:
[@timescaledocs]

*Time-centric*:
: Data records always have a timestamp.

*Append-only*:
: Data is almost solely append-only.

*Recent*:
: New data is typically about recent time intervals, and we more rarely make updates or backfill missing data about old intervals.

An instance of time series database consist of *time series table* with schema as in table \ref{tab:schema-time-series} and optional *metadata table* with schema as in table \ref{tab:schema-metadata}.
A separate metadata table reduces data bloat and makes it easier to alter its schema later.
We can join the metadata table and time series table during queries.

For the `identifier`, we use *Universally Unique Identifier (UUID)* because it is standardized and has explicit support for namespaces.
We should use a randomly generated UUID a *namespace* associated with the formatting of the `<target><job_id>` string.
If the formatting changes, we should change the namespace to avoid collision with identifiers.
If the namespace is kept secret, the UUID also anonymizes the metadata values associated with time series data.

For the `timestamp`, we should always use datetime with the *Coordinated Universal Time (UTC)* timezone instead of local timezones to avoid problems with having to convert between different timezones.

The time series table is a *TimescaleDB hypertable* with *indices* for efficient queries, *chunks* by chosen time interval for improved performance, a *compression policy* to compress data that is older than specified time to reduce storage, and a *retention policy* for dropping data that is older than specified time to limit data accumulation or for privacy and regulatory reasons.
The metadata table is regular PostgreSQL table.


## Database configuration
Field | Type | Value
---|---|----------
`identifier` | UUID |
`timestamp` | Datetime with timezone | Timestamp of the query time with UTC timezone.
`snapshot_time` | Integer | The `snapshot_time` value.
Operations from tables \ref{tab:mdt-operations} and \ref{tab:ost-operations} | Float | The `sum` counter value for the `read_bytes` and `write_bytes` operations and `samples` counter value for the other operations from the `<statistics_*>` key-value pairs.

: \label{tab:schema-jobstats-time-series}


Field | Type | Value
---|---|----------
`identifier` | UUID |
`target` | String | `<target>` value.
`job` | Integer or missing | `<job>` value if exists, otherwise missing
`uid` | Integer or missing | `<uid>` value if exists, otherwise missing.
`nodename` | String or missing | `<nodename>` value if exists, `login` for login nodes, otherwise missing.
`executable` | String or missing | `<executable>` value if exists, otherwise missing.

: \label{tab:schema-jobstats-metadata}


The `identifier` is UUID value of computer from the string `<target><job_id>`.
We need to also account for the format of `<target>` and `<job_id>` in the UUID if we change them later.
We should create indices by `(identifier, timestamp DESC)` for efficient grouping by the identifier with time interval constraints.
We can also chunk the hypertable by `(identifier, timestamp)`.
We need to cast counts to double precision floating point number in order to perform analysis on the database without type conversions.
See appendix \ref{time-series-database} for conrete examples.


## Monitoring client
The monitoring client calls the appropriate `lctl get_param` command (as explained in section \ref{querying-statistics}) at regular observation intervals to collect statistics.
The time at which the call was made is the `timestamp`.
The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and 10-minute cleanup interval.

Monitoring client parses the `target` value and for each entry, it parses the `job_id`, `snapshot_time`, and statistics values and creates a data structure with the `timestamp`, `target`, `job_id`, `snapshot_time`, and all of the parsed statistics.

We need to keep track of previously observed identifiers, in this case the raw `(<target>, <job_id>)` pairs, and the previous observation timestamp.
If we encounter an identifier that was not present in the previous observation interval, we must fill a data structure with the new `target`, `job_id`, the previous `timestamp` and zeros for `snapshot_time` and statistics to mark the beginning of time series which will be *backfilled* to the database.

Finally, we compose a message of the data as text-based format such JSON.
The monitoring clients send the message to the ingest server via HTTP.


## Ingest server
The ingest server is responsible for maintaining a connection to the database and listening to the messages from the monitoring clients, parsing them and inserts the data to the database.
For each `<target><job_id>` string in a parsed message, computes an UUID with a namespace to form an `identifier`.
Then, it forms a *time series row* as in table \ref{tab:schema-jobstats-time-series} and for the identifiers that do not yet exists in the metadata table, the ingest server forms a *metadata row* from the `identifier`, `<target>`, and parsed `<job_id>` values as in table \ref{tab:schema-jobstats-metadata}.
The server should keep memorize the recent identifiers included in the metadata table to avoid unnecessary queries the database.
Finally, the ingest server *inserts* the metadata and time series rows to the database in a batch to appropriate tables.


## Computing aggregates
Querying the database

* select a time interval and desired identifiers
* group by `identifier` to form multiple time series
* compute rate for each time series
* analyze and visualize the rates

Ideally, performed in continuous fashion as new data arrives to the database.


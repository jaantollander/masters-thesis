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

An instance of time series database consist of *time series table* with schema as in Table \ref{tab:schema-time-series} and optional *metadata table* with schema as in Table \ref{tab:schema-metadata}.
A separate metadata table reduces data bloat and makes it easier to alter its schema later.
We can join the metadata table and time series table during queries.

For the *time series identifier*, we generate a *Universally Unique Identifier (UUID)* because it is standardized and has explicit support for namespaces.

For the *timestamp*, we should always use datetime with the *Coordinated Universal Time (UTC)* timezone instead of local timezones to avoid problems with having to convert between different timezones.

The time series table is a *TimescaleDB hypertable* with *indices* for efficient queries, *chunked* by a chosen time interval for improved performance, a *compression policy* to compress data that is older than specified time to reduce storage, and a *retention policy* for dropping data that is older than specified time to limit data accumulation or for privacy and regulatory reasons.
The metadata table is regular PostgreSQL table.


## Monitoring client
The monitoring client calls the appropriate command (`lctl get_param`) as explained in Section \ref{querying-statistics}, at regular observation intervals to collect statistics.
The time at which the call was made is the timestamp.
The observation interval should be less than half of the cleanup interval for reliable reset detection.
Smaller observation interval increases the resolution but also increase the rate of data accumulation.
We used a 2-minute observation interval and 10-minute cleanup interval.

Monitoring client parses the target and all entries from the output.
For all entries, it creates a data structure with the timestamp, target, and parsed entry identifier, snapshot time and statistics listed on Tables \ref{tab:mdt-operations} and \ref{tab:ost-operations}.
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


## Ingest server and database
The ingest server is responsible for maintaining a connection to the database and listening to the messages from the monitoring clients, parsing them and inserts the data to the database.

We can generate the time series identifier as UUID from the concatenated string of target and entry identifier (`<target>:<entry_id>`) with a randomly generated UUID as *namespace* associated with the formatting of the target and entry identifier strings.
If the formatting changes, we should change the namespace to avoid collision with time series identifiers.
If the namespace is kept secret, the UUID also anonymizes the metadata values associated with time series data.

```sh
uuidgen --random
```

```
2e79b8a1-c4fc-45ba-9023-d16fdce6e3fe
```

```sh
# --name=<target>:<entry_id>
uuidgen --sha1 \
    --namespace="2e79b8a1-c4fc-45ba-9023-d16fdce6e3fe" \
    --name="scratch-OST0001:11317854:17627127:r01c01"
```

```
af854063-c381-585f-b551-ce0b6c4440a3
```


Now, we can separate the ingested data into *time series structure* and *metadata structure*.
We always append the time series structure to the time series table.

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
  "job": 11317854,
  "user": 17627127,
  "nodename": "r01c01",
  "executable": null
}
```

We can convert these structures into appropriate insert statements and send them to the database with columns named similarly as in the structures.


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

An instance of time series database consist of *time series table* with schema as in Table \ref{tab:schema-time-series} and optional *metadata table* with schema as in Table \ref{tab:schema-metadata}.
A separate metadata table reduces data bloat and makes it easier to alter its schema later.
We can join the metadata table and time series table during queries.

For the `identifier`, we use *Universally Unique Identifier (UUID)* because it is standardized and has explicit support for namespaces.

For the `timestamp`, we should always use datetime with the *Coordinated Universal Time (UTC)* timezone instead of local timezones to avoid problems with having to convert between different timezones.

The time series table is a *TimescaleDB hypertable* with *indices* for efficient queries, *chunks* by chosen time interval for improved performance, a *compression policy* to compress data that is older than specified time to reduce storage, and a *retention policy* for dropping data that is older than specified time to limit data accumulation or for privacy and regulatory reasons.
The metadata table is regular PostgreSQL table.


## Monitoring client
The monitoring client calls the appropriate command (`lctl get_param`) as explained in Section \ref{querying-statistics}, at regular observation intervals to collect statistics.
The time at which the call was made is the `timestamp`.
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

The monitoring client must also keep track of previously observed identifiers, concatenation of target and entry identifier (`<target><entry_id>`), and the previous observation timestamp.
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
Field | Type | Value
---|---|----------
`identifier` | UUID |
`timestamp` | Datetime with timezone | Timestamp of the query time with UTC timezone.
`snapshot_time` | Integer | Snapshot time.
Operations from Tables \ref{tab:mdt-operations} and \ref{tab:ost-operations} | Floating point number | The statistic of the operation.

: \label{tab:schema-jobstats-time-series}


Field | Type | Value
---|---|----------
`identifier` | UUID |
`target` | String | Target.
`entry_id` | String | Entry identifier
`job` | Integer or missing | Job ID if exists, otherwise missing
`user` | Integer or missing | User ID if exists, otherwise missing.
`nodename` | String or missing | Nodename if exists, `login` for login nodes, otherwise missing.
`executable` | String or missing | Executable name if exists, otherwise missing.

: \label{tab:schema-jobstats-metadata}


The ingest server is responsible for maintaining a connection to the database and listening to the messages from the monitoring clients, parsing them and inserts the data to the database.
For each `<target><job_id>` string in a parsed message, computes an UUID with a namespace to form an `identifier`.
Then, it forms a *time series row* as in Table \ref{tab:schema-jobstats-time-series} and for the identifiers that do not yet exists in the metadata table, the ingest server forms a *metadata row* from the `identifier`, `<target>`, and parsed `<job_id>` values as in Table \ref{tab:schema-jobstats-metadata}.
The server should keep memorize the recent identifiers included in the metadata table to avoid unnecessary queries the database.
Finally, the ingest server *inserts* the metadata and time series rows to the database in a batch to appropriate tables.

We can generate the `identifier` as UUID from the concatenated string of target and entry identifier (`<target><entry_id>`) with a randomly generated UUID as *namespace* associated with the formatting of the target and entry identifier strings.
If the formatting changes, we should change the namespace to avoid collision with identifiers.
If the namespace is kept secret, the UUID also anonymizes the metadata values associated with time series data.

```sh
NAMESPACE=$(uuidgen --random)
echo "$NAMESPACE"
```

```
2e79b8a1-c4fc-45ba-9023-d16fdce6e3fe
```

```sh
uuidgen --sha1 --namespace="$NAMESPACE" --name="<target><job_id>"
```

```
uuid2
```

```
json1
```

```
json2
```

We should create indices by `(identifier, timestamp DESC)` for efficient grouping by the identifier with time interval constraints.
We can also chunk the hypertable by `(identifier, timestamp)`.
We need to cast counts to double precision floating point number in order to perform analysis on the database without type conversions.
See appendix \ref{time-series-database} for conrete examples.


## Computing aggregates
Querying the database

* select a time interval and desired identifiers
* group by `identifier` to form multiple time series
* compute rate for each time series
* analyze and visualize the rates

Ideally, performed in continuous fashion as new data arrives to the database.


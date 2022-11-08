\newpage

# Monitoring workflow
![](figures/lustre-monitor.drawio.svg)

## Monitoring and recording the statistics
The pipeline for monitoring and recording the statistics consists of multiple instances of a monitoring daemon and a single instance of an ingest daemon, and a relational database.
*Daemon* is a program that runs in the background.
We installed a monitoring daemon to each Lustre server, and an ingest daemon and a database to a utility node on Puhti.

> TODO: change description about interval length

The Monitoring daemon calls the appropriate `lctl get_param` command at regular intervals to collect statistics.
We found that a 2-minute interval gives a sufficient resolution at a manageable rate of data accumulation.
We record the time when we collected the statistics as `timestamp`.
For each output and unique identifier (`job_id`) in `job_stats`, the program parses the values below and places them into a data structure with the following fields along with the `timestamp` field.

- `snapshot_time` to an integer type.
- `uid` to an integer type.
- `job` to an integer type.
  We generate synthetic `job` IDs for utility nodes and identifiers where only `job` is missing, but `uid` and `nodename` are intact.
- `nodename` to a string type.
- `source` to a string type.
  Login node don't have `nodename` value, thus we set it to `login`.
- `executable` to a string type. We set it to an empty string for `job_id`s without this value.
- all `<operation>`s for target to integer types.
  We parse the values the `sum` values from `read_bytes` and `write_bytes` and `samples` from the other counts.
  We omit the rest of the values.

The monitoring daemons send these data structures to the ingest daemon in batches.
The ingest daemon listens to the requests from the monitoring daemons and stores the data in a relational database such that each instance of the data structure represents a single row.
We used a PostgreSQL database with a Timescale extension.

> TODO: replace relational database as timeseries database

For a row in the relational database, the tuple of values `(uid, job, nodename, source)` forms a unique identifier, `timestamp` is time, and `<operation>` fields contain the counter values for each operation.


## Querying the database


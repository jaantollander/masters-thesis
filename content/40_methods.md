\newpage

# Methods
> - *Describe the research material and methodology*
> - *How we conducted the research and which methods we used?*

## Collecting file system metrics
Lustre keeps a counter of file system usage on each server.
We can query the values from the counter by running the command below at regular intervals.

```
lctl get_param obdfilter.*.jobstats
```

The command fetches the values and prints them in a text format, which we can parse into a data structure.
We furher process the data by computing a difference between two concecutive intervals, which tells us how many operations occured during the interval.
Each data point has the same fields for values and thus we can represent it in a tuple.
Multiple tuples form a table (aka relation), therefore, we can efficiently store the differences into a tabular format for storage and analysis.


## Interpreting jobstats output
The output for all MDTs that belong to the same MDS or OSTs of an OSS are concatenated into single output.
The raw output for each MDT and OST is formatted as below.
We indicate variables using the syntax `<name>`.

---

```text
obdfilter.<source>.job_stats=
job_stats:
- job_id: <job_id>
  snapshot_time: 1646385002
  <operation>: <values>
```

---

The `<source>` field contains a value such as `scratch-MDT0000` or `scratch-OST0000` indicating the source of the data, that is, the MDT or OST.

Below `job_stats` there are entries of statistic for each unique job has performed file system operations on the source.

The `job_id` field is either formatted as login node job `<program>.<uid>` or compute node job `<job>:<uid>:<nodename>`.
However, some of these values are missing for some jobs.

The `snapshot_time` is the Unix time epoch when the snapshot was taken.
We discard these values and use a timestamp of when we queried the data instead.

The `<values>` of  each file system `<operation>` are formatted as a key-value pairs separated by commas and enclosed within curly brackets.

---

```text
{ samples: 0, unit: <unit>, min: 0, max: 0, sum: 0, sumsq: 0 }
```

---

The `samples` field indicates how many operations since the counter was started.
The fields `min`, `max`, `sum` and `sumsq` are values of the counter with `<unit>` of either `bytes` or `usecs` (microseconds)
The the values fields contain positive integers that increase monotonically until the counter is reset.

---

Challences

Detecting counter resets from the data.
Detecting when new jobs from the data (first appears on the output).

Handing missing values, adding synthetic values.
Due to a bug in Lustre 2.x, the `<job>` values are missing for MPI jobs.


## File system operations
The data fields for each MDT are

- `open`
- `close`
- `mknod`
- `link`
- `unlink`
- `mkdir`
- `rmdir`
- `rename`
- `getattr`
- `setattr`
- `getxattr`
- `setxattr`
- `statfs`
- `sync`
- `punch`

The data fields for each OST are

- `read`
- `write`
- `readbytes`
- `writebytes`
- `getattr`
- `setattr`
- `punch`
- `sync`
- `getinfo`
- `setinfo`
- `quotactl`


## Building a data pipeline
The data pipeline consists of a database, ingest program and monitoring program.

We installed a monitoring program, which runs on the background as a daemon, querying the values every two minutes, parses them and computes the difference.
The differences are sent to database via HTTP.

Ingest program listens to the requests from the monitoring program and stores them to a relational database.


## Analyzing the metrics


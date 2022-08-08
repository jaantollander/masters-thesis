\newpage

# Methods
- Describe the research material and methodology
- How we conducted the research and which methods we used

---

## Collecting File System Metrics
Lustre keeps a counter of file system usage on each server.
We can query the values from the counter by running `lctl get_param obdfilter.*.jobstats` command at regular intervals.
The command fetches the values and prints them in a text format, which we can parse into a data structure.
We furher process the data by computing a difference between two concecutive intervals, which tells us how many operations occured during the interval.
Each data point has the same fields for values and thus we can represent it in a tuple.
Multiple tuples form a table (aka relation), therefore, we can efficiently store the differences into a tabular format for storage and analysis.


## Parsing the Raw Data
The output from the command from each MDS and OSS is formatted as follows.

```
obdfilter.<source>.job_stats=
job_stats:
- job_id: <job_id>
  snapshot_time: 1646385002
  <field>: <values>
```

The `<source>` value such as `scratch-MDT0000` or `scratch-OST0000`.

The `<job_id>` field is either formatted as login node job `<program>.<uid>` or compute node job `<job>:<uid>:<nodename>`.

The `snapshot_time` is the Unix time epoch when the snapshot was taken. We do not recored these.

The `<field>` values are formatted as below

```
{ samples: 0, unit: bytes, min: 0, max: 0, sum: 0, sumsq: 0}
```

```
{ samples: 0, unit: usecs, min: 0, max: 0, sum: 0, sumsq: 0}
```

---

Common fields

- `timestamp`
- `job`
- `uid`
- `nodename`
- `source` -- `obdfilter.scratch-OST0000.job_stats=`

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


## Data Pipeline
The data pipeline consists of a database, ingest program and monitoring program.

We installed a monitoring program, which runs on the background as a daemon, querying the values every two minutes, parses them and computes the difference.
The differences are sent to database via HTTP.

Ingest program listens to the requests from the monitoring program and stores them to a relational database.


## Analyzing the Metrics


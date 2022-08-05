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
Then, we store the differences into a database for storage and analysis.

The data pipeline consists of an database, ingest program and monitoring program. The programs are written in Go.


We installed a monitoring program, which runs on the background as a daemon, querying the values every two minutes, parses them and computes the difference. The differences are sent to database via HTTP.

Ingest program listens to the requests from the monitoring program and stores them to a PostgreSQL database with Timescale extension.


# Monitoring Lustre
There are multiple **Metadata Servers** (MDS) on the system. For each MDS there are multiple **Metadata Targets** (MDT).

There are multiple **Object Storage Servers** (OSS) on the system. For each OSS there are multiple **Object Storage Targets** (OST).

```sh
lctl get_params obdfilter.*.job_stats
```

---

Header gives us OST id.

```
obdfilter.scratch-OST0000.job_stats=
stats:
```

---

File system events are recorded to a counter and reported as the following aggregate statistics .

- `samples: <positive-integer>` number of events
- `min: <positive-integer>` minimum value in the sample
- `max: <positive-integer>` maximum value in the sample
- `sum: <positive-integer>` sum of the values in the sample
- `sumsq: <positive-integer>` sum of the values squares in the sample

Units of the `min`, `max`, `sum` and `sumsq` quantities are also recorded.

- `unit: bytes` for bytes
- `unit: usecs` for microseconds
- `unit: reqs` for requests?

---

Fields in job statistics for MDS and OSS.

- `job_id: <id>`
    - Login node `<program>.<id>` or 
    - Slurm job `<job-id>:<user-id>:<node-id>`

- `snapshot_time: <unix-epoch>` Unix time epoch when the snapshot was taken.

Lustre keeps count of the following operations.

`unit: bytes`

- `read_bytes:` Statistics for bytes read
- `write_bytes:` Statistics for bytes written

`unit: usecs`

- `read:`
- `write:`
- `getattr:`
- `setattr:`
- `punch:`
- `sync:`
- `destroy:`
- `create:`
- `statfs:`
- `get_info:`
- `set_info:`
- `quotactl:`
- `open:`
- `close:`
- `mknod:`
- `link:`
- `unlink:`
- `mkdir:`
- `rmdir:`
- `rename:`
- `getxattr:`
- `setxattr:`
- `statfs:`
- `samedir_rename:`
- `crossdir_rename:`
- `punch:`

`unit: reqs`

- `prealloc:`

---

Let's denote a stream of IO events for a job as

$$x_1,x_2,x_3,...$$

where $x_i$ is a value of individual IO event and the subscript $i$ denotes the amount of samples upto the event.

Counters keep track of aggregate values from a stream of IO events.

minimum

$$a_1=x_1, a_i=\min\{a_{i-1},x_{i}\}$$

maximum

$$b_1=x_1, b_i=\max\{b_{i-1},x_{i}\}$$

sum

$$s_1=x_1, s_i=s_{i-1}+x_i$$

sum of squares

$$q_i=x_1^2, q_i=q_{i-1}+x_i^2$$

---

Take snapshot from the counters at intervals

$$x_0,...,x_{m_1},x_{m_1+1}...,x_{m_2},...$$

Computing differences for the interval 

$$x_{m_1+1},...,x_{m_2}$$

Number of samples in the interval 

$$n_{m_1,m_2}=m_2-m_2$$

We cannot compute the minimum and maximum of the samples in the interval from the aggregates.

Sum of the samples in the interval

$$s_{m_1,m_2}=s_{m_2}-s_{m_1}$$

Sum of squares of the samples in the interval

$$q_{m_1,m_2}=q_{m_2}-q_{m_1}$$

---

From the aggregate statistics, we can compute the average value of the events

$$\mu_{m_1,m_2}=\frac{s_{m_1,m_2}}{n_{m_1,m_2}}$$

and standard deviation

$$\sigma_{m_1,m_2}=\sqrt{\frac{q_{m_1,m_2}}{n_{m_1,m_2}} - \mu_{m_1,m_2}^2}$$

---

By taking a snapshot at times $t_1,t_2,t_3,...$ we obtain a time series.

$$(t_1, \mu_{t_1}), (t_2,\mu_{t_2}), ...$$


# Monitoring Lustre
There are multiple *Metadata Servers* (MDS) on the system. For each MDS there are multiple *Metadata Targets* (MDT).

There are multiple *Object Storage Servers* (OSS) on the system. For each OSS there are multiple *Object Storage Targets* (OST).

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

$$(t_1,x_1),(t_2,x_2),...$$

where $t_i$ is the timestamp of the event, $x_i$ is a value the event, timestamps are increasing $t_1< t_2< ...$ and the subscript $i$ denotes the count of the event.

Counters keep track of aggregate values from a stream of IO events.

samples

$$n_1=1$$

$$n_i=n_{i-1}+1,\quad i>1$$

minimum

$$a_1=x_1$$

$$a_i=\min\{a_{i-1},x_{i}\},\quad i>1$$

maximum

$$b_1=x_1$$

$$b_i=\max\{b_{i-1},x_{i}\},\quad i>1$$

sum

$$s_1=x_1$$

$$s_i=s_{i-1}+x_i,\quad i>1$$

sum of squares

$$q_i=x_1^2$$

$$q_i=q_{i-1}+x_i^2,\quad i>1$$

---

Consider we take snapshot of the counter at time $\tau.$ Then, we obtain index

$$m(\tau)=\max\{i\in\mathbb{N}\mid t_i\le\tau\}$$

Subsuquently, if we take snapshot from the counters at interval

$$\tau, \tau^\prime,\quad \tau< \tau^\prime$$

Then

$$k=m(\tau)\le m(\tau^\prime)=k^\prime$$

Then, the intervals consist of events like

$$x_0,...,x_{k},...,x_{k^\prime}$$

Number of samples in the interval 

$$n_{k,k^\prime}=n_{k^\prime}-n_k$$

We cannot compute the minimum and maximum of the samples in the interval from the aggregates.

Sum of the samples in the interval

$$s_{k,k^\prime}=s_{k^\prime}-s_{k}$$

Sum of squares of the samples in the interval

$$q_{k,k^\prime}=q_{k^\prime}-q_{k}$$

---

From the aggregate statistics, we can compute the average value of the events

$$\mu_{k,k^\prime}=\frac{s_{k,k^\prime}}{n_{k,k^\prime}}$$

and standard deviation

$$\sigma_{k,k^\prime}=\sqrt{\frac{q_{k,k^\prime}}{n_{k,k^\prime}} - \mu_{k,k^\prime}^2}$$

---

The counter will reset if there are no events in some defined cutoff time $T$.

$$t_{k^\prime}-t_k>T$$

We can detect that counters have reset if values in the counter have decreased. If we detect that the counter has reset during the measuring interval, for example, if $n_k>n_{k^\prime},$ we will 

We can deal with resetting counter by setting 

$$n_{k,k^\prime}=n_{k^\prime}$$

$$s_{k,k^\prime}=s_{k^\prime}$$

$$q_{k,k^\prime}=q_{k^\prime}$$


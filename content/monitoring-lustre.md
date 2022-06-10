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

Fields in job statistics for OSS

- `job_id: <id>`
    - Login node `<program>.<id>` or 
    - Slurm job `<job-id>:<user-id>:<node-id>`

- `snapshot_time: <unix-epoch>`

---

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

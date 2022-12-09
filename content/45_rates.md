## Counters and rates
In this section, we show examples of the sampled counter values and rates computed from the counters.
The Figures \ref{fig:job-rate-1}, \ref{fig:job-rate-2}, and \ref{fig:job-rate-3}, each line shows write operations performed by from a compute node to an OST for the same job during 24 hours in 2022-10-27.

TODO: connection; node to target, explain units operations per second, bytes per second

![
The upper graph shows a typical saw-tooth pattern for near linearly increasing counter values which reset periodically.
The lower graph shows steady rates of writes during the active periods.
\label{fig:job-rate-1}
](figures/2022-10-27_ost_job_write_1.svg)

![
The upper graph shows near linearly increasing counter values for a job that consistently performs writes during the whole period.
The lower graph shows a steady rate over the whole period with some small fluctuations.
\label{fig:job-rate-2}
](figures/2022-10-27_ost_job_write_2.svg)

![
The upper graph shows a wave-like pattern of increasing counter values which reset periodically.
The lower graph reveals a fluctuating rate.
\label{fig:job-rate-3}
](figures/2022-10-27_ost_job_write_3.svg)


\clearpage

## Total rates
In this section, we show total rates for various operations operations on all targets.
We use logaritmic scale due to large variations in rates.
Figures \ref{fig:total-open-close-mknod-unlink} and \ref{fig:total-read-write-readbytes-writebytes} shows examples of total rates for some MDT and OST operations.

TODO: plot all attributes, as many subplots as fits on one page with caption and text

![
Total open and close rates from compute nodes to each MDT during 2022-10-27.
\label{fig:total-open-close-mknod-unlink}
](figures/2022-10-27_mdt_compute_open-close-mknod-unlink.svg)

![
hello
\label{fig:total-read-write-readbytes-writebytes}
](figures/2022-10-27_ost_compute_read-write-readbytes-writebytes.svg)


\clearpage

## Total rates and densities
![hello](figures/2022-10-27_ost0001_compute_read.svg)

![hello](figures/2022-10-27_ost0001_compute_write.svg)


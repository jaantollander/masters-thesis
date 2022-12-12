## Counters and rates
This section shows examples of the sampled counter values and rates computed from the counters.
We refer to operations from a Lustre client (node) to a Lustre target as a *connection*.
Figures \ref{fig:job-rate-1}, \ref{fig:job-rate-2}, and \ref{fig:job-rate-3} show different patterns of counter values and the computed rates for write operations for 24 hour-period of 2022-10-27. 
Each line displays the values for a connection from a compute node to an OST for the same job.
The x-axis displays time, and the y-axis displays the accumulated amount of operations for counters and the operations per second for the rate.

![
The upper graph shows a typical saw-tooth pattern for near-linearly increasing counter values that resets periodically.
The lower graph shows steady rates of writes during the active periods.
\label{fig:job-rate-1}
](figures/2022-10-27_ost_job_write_1.svg)

![
The upper graph shows near linearly increasing counter values for a job that consistently performs writes during the whole period.
The lower graph shows a steady rate over the whole period with some small fluctuations.
\label{fig:job-rate-2}
](figures/2022-10-27_ost_job_write_2.svg)

![
The upper graph shows a wave-like pattern of increasing counter values that reset periodically.
The lower graph reveals a fluctuating rate.
\label{fig:job-rate-3}
](figures/2022-10-27_ost_job_write_3.svg)


\clearpage

## Total rates
This section shows the total rates from all compute nodes to each target for each measured operation, listed in Table \ref{tab:operations}.
Please note that we use a logarithmic scale due to large variations in the magnitude of the rates.
We show the total rates during 24 hours of 2022-10-27 for MDTs in Figures \ref{fig:total-mdt-1}, \ref{fig:total-mdt-2} and \ref{fig:total-mdt-3}, and for OSTs in Figures \ref{fig:total-ost-1} and \ref{fig:total-ost-2}.

![\label{fig:total-mdt-1}](figures/2022-10-27_mdt_compute_1.svg)

![\label{fig:total-mdt-2}](figures/2022-10-27_mdt_compute_2.svg)

![\label{fig:total-mdt-3}](figures/2022-10-27_mdt_compute_3.svg)

![\label{fig:total-ost-1}](figures/2022-10-27_ost_compute_1.svg)

![\label{fig:total-ost-2}](figures/2022-10-27_ost_compute_2.svg)


\clearpage

## Total rates and densities
![hello](figures/2022-10-27_ost0001_compute_read.svg)

![hello](figures/2022-10-27_ost0001_compute_write.svg)


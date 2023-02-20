\clearpage

## Counters and rates
We explore I/O patterns at the most fine-grained level by visualizing data from three selected jobs.
Figures \ref{fig:job-rate-1}, \ref{fig:job-rate-2}, and \ref{fig:job-rate-3} show us different patterns of counter values and rates for `write` operations for different jobs during 24 hours of 2022-10-27.
The figures demonstrate the fine-grained nature of the monitoring data and entry resets discussed in Section \ref{monitoring-system}.

The x-axis displays time and the y-axis displays the accumulated amount of operations for counters and the operations per second for the rate.
Each line displays operations from one Lustre client to one Lustre target.
The figures in this subsection display a single node job; thus, each line shows `write` operations from the same compute node to a different OST.
We say that a job is active during a period that performs any file system operations; otherwise, it is inactive.

![
The counter and rate of `write` operations from one job on a single compute node.
The top subplot shows the counter values, and the bottom subplot shows the rates computed from the counter values in the first plot.
The subplots share the same x-axis.
The counter values follow a typical saw-tooth pattern for almost linearly increasing counter values that reset periodically due to inactivity.
In the active periods, we see a higher write amount of writes in the beginning, then quite near constant write rate until the job becomes inactive.
The lines follow a similar pattern indicating that the job performs a similar write pattern for each OST except for the ones whose rate is near zero.
\label{fig:job-rate-1}
](figures/2022-10-27_ost_job_write_1.svg)

![
The counter and rate of `write` operations from one job on a single compute node.
The top subplot shows the counter values, and the bottom subplot shows the rates computed from the counter values in the first plot.
The subplots share the same x-axis.
The counter values increase almost linearly, indicating that the job performs writes consistently during the whole period.
The rate over the whole period is almost constant with some small fluctuations.
We can see that the job performs almost 75\% of the operations to one OST, almost 25\% to two other OSTs, and almost none to the others.
\label{fig:job-rate-2}
](figures/2022-10-27_ost_job_write_2.svg)

![
The counter and rate of `write` operations from one job on a single compute node.
The top subplot shows the counter values, and the bottom subplot shows the rates computed from the counter values in the first plot.
The subplots share the same x-axis.
One of the counter values increases in a wave-like pattern that resets periodically; the other counter seems to increase in a burst-like manner for short periods before resetting.
By looking at the rates, we can see that the rates fluctuate for all OSTs.
Furthermore, most of the time, the job performs writes to one OST and sometimes to multiple OSTs in a burst.
\label{fig:job-rate-3}
](figures/2022-10-27_ost_job_write_3.svg)

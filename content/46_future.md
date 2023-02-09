\clearpage

## Future work
In the future, we aim to gather reliable data over a longer period either by using patched version of Lustre Jobstats or different monitoring tool.
We should verify data correctness by running jobs with known I/O work and comparing them with the monitoring data.
We can use the monitoring data to perform more extensive analysis and to develop automatic, real-time analysis methods.
Here are some ideas for the future analysis methods.

We analyzed operations independently.
However, we should model the dependecy of different operations by *combining operations* of the same unit using a linear combination with appropriate weights and analyze the resulting time series.
For example, we can combine the rates of metadata operations that read data from disk or that write data to disk.

We can also *analyze trends* of a time series by using a causal, impulse response filter such as moving average with finite time window.
Furthermore, we can *identify changes in trends* by filtering a time series with different time window lengths and comparing the filtered time series.
The intersections of between two filtered time series indicate points in time where the trends change.
For example, given a time series such as a total rate of an operation or a linear combination of operations, we could compare its moving average with short, ten-minute time window against long, one-day time window to identify transient changes against a longer trend.

Furthermore, with reliable identifiers we can combine Slurm accounting data, such as project and partition information, as metadata to the analysis.
For example, we can use project information to identify if members of particular project perform heavy I/O and partition information to identify if jobs on particular partition perform heavy I/O.

Finally, we should compare the file system usage data with file system performance metrics to identify what kind of usage causes a slowdown in the cluster.
Currently, we have probes that periodically measure the parallel file system performance.
We should measure correlation between the these measurements and file system usage data.
Also, it might be interesting to collect and analyze latency values from Lustre Jobstats to see if they provide useful information.

Analysing monitoring data as a *batch* is fine for exploring the data and experimenting with different analysis methods.
However, to build a real-time monitoring system, we must process and analyze the monitoring data as a *stream*.
We must implement our analysis methods to stream computing, that is, computing the rates and analytics on new data as soon as it arrives from a monitoring client.
We should also build real-time visualization and reporting of the analysis results.

<!-- To improve reaction time, we could reduce the observation interval from 2-minutes to 1-minute. -->
<!-- We aim to offer job-specific I/O statistics to users. -->

<!--
Another interesting analysis method is using *cluster analysis*.
We can assign groups for multiple time series with similar values using one-dimensional clustering at each timestamp and then analyze how the cluster for each time series evolves in time.
We could describe each cluster with using summary statistics such as the number of samples, min, max, mean, and deviation from the mean.
For example, we could use Average Shifted Histograms [@ash] to perform fast one-dimensional clustering.
-->


\clearpage

## Future work
Analysing monitoring data as a batch is fine for exploring the data and exprerimenting with different analysis methods.
However, to build a real-time monitoring system, we must process and analyze the monitoring data as a stream instead.
It means computing the rates and performing real-time analytics on them as soon as new data arrives from the monitoring clients.
Furthermore, with reliable identifiers, we hope to offer job-specific statistics to users and combine Slurm accounting data, such as project and partition information, for adding metadata to the analysis.

In the future, we aim to gather reliable data over a longer period either by using patched version of Lustre Jobstats or different monitoring tool.
We should verify data correctness by running jobs with known I/O work and comparing them with the monitoring data.
We will use the monitoring data to perform more extensive analysis and develop automatic, real-time analysis methods.
Here are some ideas of those analysis methods.

- *Combining operations*:
  We analyzed operations independently.
  Alternatively, we could combine multiple rates with the same units into one using a linear combination.
  For example, we can sum the rates of metadata operations that read data from disk or that write data to disk.

- *Aggregation methods*:
  We showed sum aggregates.
  Alternatively, we could use different ways to aggregate multiple time series into one.
  For example, we could sum by the user and computing the average over the sums.

- *Analyzing trends*:
  To analyze trends of a time series, we could apply a causal, impulse response filter on it.
  For example, we the moving average with finite time window is commonly used causal, impulse response filter.

- *Identify changes in trends at different timescales*:
  We can identify periods where trends change by applying the same filter at different time windows to a time series.
  The intersections of two of the filtered time series indicate times where the trends change.
  For example, we could compare a moving average with ten-minute and one-day time windows.

- *Cluster analysis*:
  We can assign groups for multiple time series with similar values using one-dimensional clustering at each timestamp and then analyze how the cluster for each time series evolves in time.
  We could describe each cluster with using summary statistics such as the number of samples, min, max, mean, and deviation from the mean.
  For example, we could use Average Shifted Histograms [@ash] to perform fast one-dimensional clustering.

These methods are composable which means that we can combine them.
Finally, we want to compare the file system usage data with file system performance metrics to identify what kind of usage causes a slowdown in the cluster.
To improve reaction time, we could reduce the observation interval from 2-minutes to 1-minute.
<!-- We could also collect and analyze latency values. -->

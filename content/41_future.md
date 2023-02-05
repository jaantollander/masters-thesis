\clearpage

## Future work
<!-- TODO: ideas for future developement with larger amount of reliable data -->
<!-- TODO: wanted to do in this thesis but could not -->
In the future, we should analyze the monitoring data as a stream, not as a batch.
We would like to compute the rates on the database as new data arrives and perform real-time analytics on them.
We hope that the vendor fixes these issues so that we can gather reliable data over a longer period to perform more extensive analysis.
<!--
As a recap, the monitoring data of each file system operation consists of multiple time series.
Each time series consists of timestamps and associated values.
Each value tells us the average rate of operations from the previous timestamp to the current timestamp.
-->
Here are some ideas of analysis methods we could try:

- *Combining operations*:
  We analyzed operations independently.
  We can try combining multiple rates with the same units into one using a linear combination.
  For example, we can sum the rates of metadata operations that read data from disk.
  We can also sum the rates of metadata operations that write data to disk.

- *Aggregation methods*:
  We can try different ways to aggregate multiple time series into one.
  For example, we showed sum aggregates in Section \ref{results}.
  We can also try summing by the user and computing the average over the sums.

- *Analyzing trends*:
  We can apply a causal, impulse response filter on a time series to analyze trends over time.
  For example, we can use a moving average on a time series.

- *Identify changes in trends at different timescales*:
  We can identify periods where trends change by comparing multiple applying the same filter at various time windows to a time series.
  The trends change at the intersections.
  For example, we could compare ten-minute, one-hour, and one-day time windows.

- *Cluster analysis*:
  We can assign groups for multiple time series with similar values using one-dimensional clustering at each timestamp.
  We can analyze how the cluster for each time series evolves in time.
  We can use Kernel Density Estimation (KDE), such as Average Shifted Histograms to perform fast one-dimensional clustering.

<!-- TODO: composable methods -->
We can also combine these methods.

With reliable data and complete identifiers, we should be able to offer job-specific statistics to users and combine Slurm accounting data, such as project and partition information, for the analysis.
Also, we want to compare the file system usage data with file system performance metrics to identify what kind of usage causes a slowdown in the cluster.
<!-- TODO: collect and analyze latency values? -->
<!-- TODO: reducing the observation interval from 2-minutes to 1-minute. -->
We should verify data correctness by running jobs with known I/O work and comparing them with the monitoring data.

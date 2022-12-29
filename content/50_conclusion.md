\clearpage

# Conclusion
In this work, we explored monitoring and analyzing the usage of a parallel file system and whether it could help us to identify slowdowns and their causes.
We explained the basic building blocks of a high-performance computing system.
We covered the configuration of the Puhti cluster at CSC from a storage perspective.
We developed a monitoring system, deployed it on the Puhti cluster, and collected file system data.
During the data analysis, we uncovered issues with data quality which turned out to be caused by a bug in the Lustre jobstats feature that we used for collecting data.
The issues lead us to modify the monitoring system and data analysis.
We had to analyze raw data to identify the cause of the issue and correct it to the extent possible.
Unfortunately, we lost valuable time and data due to the issues; therefore, we could not complete the initial goals of creating an automated analysis to identify file system usage which caused a slowdown in the cluster.
Fortunately, we obtained data that we believe to be reliable and used it for analysis and visualization.
The results demonstrate different usage patterns and total rates for all the monitored file system operations.
The data demonstrate that an individual user can cause the majority of file system operations at a given time.

In the future, we hope that the vendor fixes these issues so that we can gather reliable data over a longer period to perform a more extensive analysis.
We should verify data correctness by running jobs with known I/O work and comparing them with the monitoring data.
With reliable data and complete identifiers, we should be able to offer job-specific statistics to users and combine Slurm accounting data for the analysis.
Also, we want to compare the file system usage data with file system performance metrics to identify what kind of usage causes lag in a slowdown in the cluster and who is responsible for it.

As a recap, the monitoring data of each file system operation consists of multiple time series.
Each time series consists of timestamps and associated values.
Each value tells us the average rate of operations from the previous timestamp to the current timestamp.
Here are some ideas for more sophisticated analysis methods to try.

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
  We can apply a causal, finite impulse response filter on a time series to analyze trends over time.
  For example, we can use a (weighted) moving average to a time series.

- *Identify changes in trends at different timescales*:
  We can identify periods where trends change by comparing multiple applying the same filter at various time windows to a time series.
  The trends change at the intersections.
  For example, we could compare ten-minute, one-hour, and one-day time windows.

- *Cluster analysis*:
  We can assign groups for multiple time series with similar values using one-dimensional clustering at each timestamp.
  We can analyze how the cluster for each time series evolves in time.
  We can use Kernel Density Estimation (KDE), such as Average Shifted Histograms to perform one-dimensional clustering fast.

The ultimate goal is to provide real-time monitoring, visualization, and reporting deployed on a live system that administrators can use to identify if a slowdown is caused by file system usage and who is causing it.


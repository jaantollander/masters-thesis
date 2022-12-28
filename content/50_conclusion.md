\clearpage

# Conclusion
In this work, we explored if monitoring the usage of a parallel file system can help us identify problems and their causes.
We explained the basic building blocks of a high-performance computing system and covered the configuration of the Puhti cluster at CSC from a storage perspective.
We developed a monitoring system, deployed it on the Puhti cluster, and collected file system data.
During the data analysis, we uncovered issues with data quality which turned out to be caused by a bug in a part of the Lustre jobstats feature used for collecting data.
We had to modify the monitoring system and data analysis and analyze raw data to identify the issue and correct it to the extent possible.
We lost valuable time and data due to the issues; therefore, we could not complete the initial goals of creating an automated analysis to identify workloads performing I/O that cause lag in the cluster.
Fortunately, we obtained data that we believed to be reliable and used it for analysis and visualization.
The results demonstrate different I/O patterns, all the monitored file system operations, and the corresponding total rates.
We also demonstrate that an individual user can cause the majority of file system operations at a given time.

In the future, we hope that the vendor fixes these issues so that we can gather reliable data over a longer period to perform a more extensive analysis.
With reliable data and correct job IDs, we should be able to offer job-specific statistics to users and combine Slurm accounting data for the analysis.
Also, we want to compare the file system usage data with file system performance metrics to identify what kind of usage causes lag in slow-down in the cluster and who is responsible for it.

We should experiment with different analysis methods.

- Multiple time series for each file system operation
- Combine rates of different operations into one (for example, as a linear combination)
- For example, we can try different ways to aggregate multiple time series into one (for example, sum by user and average over each timestamp), 
- Then apply causal impulse response filter on the aggregate time series (for example, moving average).
- Compare multiple filtered time series with varying time windows (find intervals from the intersections).
- Compare aggregate time series against the filtered time series (for example, measure deviation to find outliers).

The ultimate goal is to provide a real-time monitoring, visualization and reporting deployed on live system that administrators can use to identify if slow-down is caused by file system usage and who is causing it.


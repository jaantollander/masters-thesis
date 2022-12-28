\clearpage

# Conclusion
In this work, we explored how to monitor and analyze the usage of a parallel file system and whether it could help us to identify slow-downs and their causes.
We explained the basic building blocks of a high-performance computing system and covered the configuration of the Puhti cluster at CSC from a storage perspective.
We developed a monitoring system, deployed it on the Puhti cluster, and collected file system data.
During the data analysis, we uncovered issues with data quality which turned out to be caused by a bug in a part of the Lustre jobstats feature used for collecting data.
We had to modify the monitoring system and data analysis and analyze raw data to identify the issue and correct it to the extent possible.
We lost valuable time and data due to the issues; therefore, we could not complete the initial goals of creating an automated analysis to identify file system usage that causes slow-down in the cluster.
Fortunately, we obtained data that we believe to be reliable and used it for analysis and visualization.
The results demonstrate different usage patterns and total rates for all the monitored file system operations.
The data demonstrates that an individual user can cause the majority of file system operations at a given time.

In the future, we hope that the vendor fixes these issues so that we can gather reliable data over a longer period to perform a more extensive analysis.
With reliable data and correct job IDs, we should be able to offer job-specific statistics to users and combine Slurm accounting data for the analysis.
Also, we want to compare the file system usage data with file system performance metrics to identify what kind of usage causes lag in slow-down in the cluster and who is responsible for it.

As a recap, the data consists of multiple time series for each file system operation.
Each time series consists of the average rates between intervals.
We could experiment with different analysis methods.

- Analyze rates of operations independently or combine them into one, for example, using a linear combination.
- Aggregate multiple time series into one, for example, summing by user and averaging over the sums.
- Apply causal impulse response filter on the aggregate time series to analyze trends over time, for example, by using a moving average.
- Compare multiple filtered time series with varying time windows.
- Identify different periods where trends change from the intesections.
- Compare aggregate time series against the filtered time series, for example, measure deviation to find outliers.

The ultimate goal is to provide a real-time monitoring, visualization and reporting deployed on live system that administrators can use to identify if slow-down is caused by file system usage and who is causing it.


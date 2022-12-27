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
We want to compare the file system usage data with file system performance metrics to identify what kind of usage causes lag in slow-down in the cluster.
It would be interesting to combine Slurm accounting data and use it in the analysis.

- apply causal impulse response filter on total rate per target, compare individual rates against the filtered rate?
- finite or infinite time window, experiment with different time windows
- try using moving aggregates (average, median) with multiple time windows to analyze time series data
- find time intervals from the intersections of the moving aggregates
- measure deviation from the moving aggregate to find outliers
- identify periods of high-load (that correlate with lag), identify who causes the majority of the load during the period

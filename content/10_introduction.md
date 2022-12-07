\newpage

# Introduction
Persistent data storage is an essential part of a computing system.
Many high-performance computer clusters rely on a global, shared, parallel file system for large storage capacity and bandwidth.
This file system is available across the whole system, making it user-friendly but prone to problems from heavy use or misuse.
Furthermore, these problems can slow down or even halt the whole system, harming all users who perform operations on the file system, not just the ones responsible for the problem.
In this thesis, we investigate if monitoring file system usage can help identify the causes of these issues and the users responsible for them.

TODO: reorder, start with the big picture, I/O intensive work, where we are going, from general to specific, figure to introduction (monitoring, parallel file system)

We experiment with the file system usage monitoring on the *Puhti* cluster at *CSC*.
Currently, we have only system-level load monitoring from processor usage and job information from the workload manager without any metrics from the file system usage.
However, load monitoring only tells us if file system problems occur but do not identify their causes.
Currently, administrators have to determine the causes manually.
However, the problem often disappears before they have identified the actual cause.
Active monitoring of file system usage should help system administrators to identify the causes and take action as the issues occur, not afterward.
It should also reduce the amount of manual work involved.

Puhti uses the Lustre parallel file system.
We can collect fine-grained statistics on file system usage with Lustre Jobstats, such as how many file operation requests there are for each job and each user from each node to each Lustre target.
We can query these statistics at regular intervals to obtain time series data, which we can process into file system metrics.
Our objective is to obtain insights and understand the causes of issues from these metrics using time series analysis and visualization techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.
Our goal is to create active monitoring and near real-time warning systems to identify users whose programs cause problems in the file system.
Real-time monitoring should provide valuable information for improving the usability and throughput of the system.

<!--
Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.
-->

<!-- related work -->
Next, we have a brief overview of the previous work regarding issues and solutions for performing heavy file I/O, monitoring and analyzing file system performance and usage statistics, and general work for improving parallel file systems.
We start with a highly relevant paper [@tacc-io-guideline] from Texas Advanced Computing Center (TACC).
Its authors discuss common issues related to heavy file I/O on a parallel file system, various novel tools designed to solve or alleviate the problems, and provide general guidelines for avoiding them.
In Table 2, they list problematic practices and solutions such as:

* Using many small files instead of a few large files.
* Having too many files in a single directory instead of using subdirectories or local temporary storage.
* Not striping large files; we should stripe large files.
* Performing suboptimal file I/O patterns, such as repeatedly opening and closing the same file, which we should avoid.
* Performing high-frequency file I/O instead of keeping data in memory or limiting the I/O frequency.
* Accessing the same file from multiple processes simultaneously instead of creating copies of the file or using parallel I/O libraries.
* Overlooking I/O patterns workloads; we should use I/O profiling tools.

We have found similar problems in the Puhti cluster.

In another paper [@year-in-life-of-parallel-file-system], the authors used multiple I/O performance probes to measure the performance of a parallel file system of multiple computer clusters at National Energy Research Scientific Computing Center (NERCS) and Argonne Leadership Computing Facility (ALCF)  for over a year.
They applied statistical methods and time series analysis to identify variations in long and short-term performance trends from the data.
Their work provides excellent insight into understanding the behavior of parallel file systems, monitoring and analysis techniques of parallel file systems, and how to improve them.
They show that short transient issues differ from long persistent ones and that the baseline performance changes over time.
They also mentioned different monitoring levels, such as application-level monitoring, file system workload monitoring, file system capacity and health monitoring, resource manager monitoring, and tracking changes and updates to the system.

In a study [@understanding-io-behaviour] conducted by Lawrence Livermore National Laboratory (LLNL),  the authors collected and analyzed statistics of file system usage from two clusters to obtain insights for improving storage design.
Their methods included analyzing general I/O share and read versus write patterns of a large number of jobs over a one-year duration.
Other computing centers, such as the Oak Ridge Leadership Computing Facility (OLFC)  and National Computational Infrastructure (NCI),
have also employed file system usage monitoring [@lustre-job-stats-metric-aggregation; @fine-grained-file-system-monitoring]
A discussion with the admins of the Aalto Scientific Computing revealed that they use a commercial product, the *View for ClusterStor* from Cray Inc [@view-for-clusterstor], for monitoring.
Another example of a commercial product for monitoring is *DDN Insight* [@ddn-insight] from DataDirect Networks (DDN).

There is also a body of research into developing and improving the performance of parallel file systems.
For example, the paper [@efficient-metadata-indexing] presents performance improvements for indexing and querying.

TODO: add couple more references

<!-- outline -->
The thesis is structured as follows.
In Section \ref{high-performance-computing}, we present a general overview of high-performance computing and related software.
Section \ref{puhti-cluster-at-csc} covers the configuration of the Puhti cluster.
In Section \ref{collecting-usage-statistics-with-lustre-jobstats}, we explain how we collect file system usage statistics with Lustre Jobstats.
We describe our monitoring system in Section \ref{monitoring-system} and how we analyze the statistics in Section \ref{analyzing-statistics}.
Finally, we present our result in Section \ref{results}.


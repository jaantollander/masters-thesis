\newpage

# Introduction
File storage is an essential part of any computing system for persistent data storage.
Many high-performance computer clusters rely on a global, shared, parallel file system for large storage capacity and bandwidth.
This file system is available for all users on the whole system, making it user-friendly but prone to problems from heavy use or misuse.
Furthermore, these problems can noticeably slow down the whole system, harming all users, not just the users responsible for the problem.
In this thesis, we investigate if file system usage monitoring can help identify the causes of these issues and the users responsible for them.

In practice, we monitor the file system usage on the *Puhti* cluster at *CSC*.
Currently, there's only system-level load monitoring from processor usage and job information from the workload manager without any metrics from the file system usage.
However, load monitoring only tells us if problems occur but do not identify their causes.
The file system usage metrics should help us identify the causes.
When file system issues emerge, administrators have to determine the reason manually.
However, the problem often disappears before they have identified the actual cause.
With active monitoring, system administrators should be able to identify the causes and take action as the issues occur, not afterward.
It should also reduce the amount of manual work involved.

We can collect statistics on file system usage with Lustre Jobstats.
We can query these statistics at regular intervals to obtain time series data, which we can process into file system metrics.
Our objective is to obtain insights and understand the causes of issues from these metrics using data visualization and analysis techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.
Our goal is to create active monitoring and near real-time warning systems to identify users whose programs cause problems in the file system.
Real-time monitoring should provide valuable information for improving the usability and throughput of the system.

<!--
Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.
-->

<!-- outline -->
<!-- background -->
In Section \ref{high-performance-computing}, we present a general overview of high-performance computing, including computer clusters and the Lustre file system.
Section \ref{puhti-cluster-at-csc} covers the configuration of the Puhti cluster.
<!-- methods -->
In Section \ref{collecting-usage-statistics-with-lustre-jobstats}, we explain how to collect file system usage statistics with Lustre Jobstats.
We describe our monitoring system in Section \ref{monitoring-system} and how we analyze the statistics in Section \ref{analyzing-statistics}.

<!-- results -->
TODO: We present our result in Section \ref{results}.

<!-- related work -->

Previous work exists regarding issues and solutions for performing heavy file I/O, monitoring and analyzing file system performance and usage statistics, and general work for improving parallel file systems.

The authors of [@tacc-io-guideline] discuss common issues related to heavy file I/O on a parallel file system, various novel tools designed to solve problems caused by heavy file I/O, and provide general guidelines for avoiding problems.
Problematic practices include using many small files instead of a few large files, too many files in a single directory, inappropriate striping, suboptimal file I/O patterns such as opening and closing the same file multiple times, performing unnecessary file I/O, and accessing the same file from multiple processes simultaneously.
They provide solutions for the problematic practices drawn from practical experience in operating systems at the *Texas Advanced Computing Center (TACC)*.

The authors of [@year-in-life-of-parallel-file-system] present used multiple I/O performance probes to measure the performance of a parallel file system of multiple computer clusters at *National Energy Research Scientific Computing Center (NERCS)* and *Argonne Leadership Computing Facility (ALCF)*  for over a year.
They applied statistical methods and time series analysis to identify variations in long and short-term performance trends from the data.
Their work provides excellent insight into understanding the behavior of parallel file systems, monitoring and analysis techniques of parallel file systems, and how to improve them.
They show that short transient issues differ from long persistent ones and that the baseline performance changes over time.
They also mention that we can monitor on different levels, such as application-level monitoring, file system workload monitoring, file system capacity and health monitoring, resource manager monitoring, and tracking changes and updates to the system.

The authors of [@understanding-io-behaviour] collected and analyzed statistics of file system usage from two clusters in *Lawrence Livermore National Laboratory (LLNL)* to obtain insights for improving storage design.
Their methods included analyzing general I/O share and read versus write patterns of a large number of jobs over a one-year duration.

Other computing centers have also employed file system usage monitoring, such as the *Oak Ridge Leadership Computing Facility (OLFC)* [@lustre-job-stats-metric-aggregation] and *National Computational Infrastructure (NCI)* [@fine-grained-file-system-monitoring].
A discussion with the admins of the *Aalto Scientific Computing* revealed that they use a commercial product, the *View for ClusterStor* from *Cray Inc* [@view-for-clusterstor], for monitoring.
Another commercial product for monitoring is *DDN Insight* [@ddn-insight] from *DataDirect Networks (DDN)*.

Regarding developing and improving the performance of parallel file systems, [@efficient-metadata-indexing] presents improvements for indexing and querying performance.

\newpage

# Introduction
File storage is an essential part of any computing system for persistent data storage.
Many large-scale computing systems, such as computer clusters, rely on a global, shared, parallel file system for large amounts of storage capacity and bandwidth.
This file system is available for all users on the whole system, making it user-friendly but prone to problems from heavy use or misuse.
Furthermore, these problems can noticeably slow down the whole system, harming all users, not just the users responsible for the problem.
In this thesis, we investigate if file system monitoring can effectively identify the causes of these issues and the users responsible for them in the *Lustre* parallel file system.
We give a general overview of high-performance computing, including computer clusters and the Lustre file system, in Section \ref{high-performance-computing}.

Previous work exists regarding issues and solutions for performing heavy file I/O on a Lustre file system.
The authors of [@tacc-io-guideline] discuss common issues related to heavy file I/O on a parallel file system, various novel tools designed to solve problems caused by heavy file I/O, and provide general guidelines for avoiding problems.
Problematic practices include using many small files instead of a few large files, too many files in a single directory, inappropriate striping, suboptimal file I/O patterns such as opening and closing the same file multiple times, performing unnecessary file I/O, and accessing the same file from multiple processes simultaneously.
They provide solutions for the problematic practices drawn from practical experience in operating systems at the *Texas Advanced Computing Center (TACC)*.

Previous work in monitoring and analyzing file system statistics exists.
The Lustre monitoring and statistics guide [@lustre-monitoring-guide] presents a general framework and existing tools.

The authors of [@understanding-io-behaviour] collected and analyzed usage statistics of file system usage from two clusters in *Lawrence Livermore National Laboratory (LLNL)* to obtain insight for improving storage design.
Their methods included analyzing general I/O share and read versus write patterns of a large number of jobs over a one-year duration.

Other computing centers have also employed file system usage monitoring.
For example, the *Oak Ridge Leadership Computing Facility (OLFC)* [@lustre-job-stats-metric-aggregation] and *National Computational Infrastructure (NCI)* [@fine-grained-file-system-monitoring] have collected job statistics from Lustre.
Discussions with the admins of the *Aalto Scientific Computing* revealed that they use a commercial product called *View for ClusterStor* by *Cray Inc* [@view-for-clusterstor] for collecting Lustre job statistics.

There is also another commercial product from *DataDirect Networks (DDN)* called *DDN Insight* [@ddn-insight].

Regarding developing and improving the performance of parallel file systems.

TODO: [@efficient-metadata-indexing], [@year-in-life-of-parallel-file-system]

In practice, we monitor the file system usage on the *Puhti* cluster at *CSC*, whose configuration we cover in Section \ref{puhti-cluster-at-csc}.
Currently, there's only system-level load monitoring from processor usage and job information from the workload manager without any metrics from the file system usage.
However, load monitoring only tells us if problems occur but do not identify their causes.
The file system usage metrics should help us identify the causes.
When file system issues emerge, administrators have to determine the reason manually.
However, the problem often disappears before they have identified the actual cause.
With active monitoring, system administrators should be able to identify the causes and take action as the issues occur, not afterward.
It should also reduce the amount of manual work involved.

We can collect statistics on file system usage with Lustre Jobstats, which we discuss in Section \ref{collecting-usage-statistics-with-lustre-jobstats}.
We can query these statistics at regular intervals to obtain time series data, which we can process into file system metrics.
Our objective is to obtain insights and understand the causes of issues from these metrics using data visualization and analysis techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.
Our goal is to create active monitoring and near real-time warning systems to identify users whose programs cause problems in the file system.
Real-time monitoring should provide valuable information for improving the usability and throughput of the system.
We describe our monitoring system in Section \ref{monitoring-system} and how we analyze the statistics into metrics in Section \ref{analyzing-statistics}.

<!--
Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.
-->

TODO: We present our result in Section \ref{results}.


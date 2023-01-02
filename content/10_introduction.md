\clearpage

# Introduction
<!--
TODO
- add a figure to the introduction (monitoring, parallel file system)
- start with the big picture
- move from general description to specific
- where we are going
-->

Persistent data storage is an essential part of a computing system.
Many high-performance computing (HPC) systems, typically computer clusters, rely on a global, shared, parallel file system for large storage capacity and bandwidth.
This file system is available across the entire system, making it user-friendly but prone to problems from heavy use.
Heavy use may be intentional, such as data-intensive computing, or unintentional, such as running a program that creates many temporary files.
Heavy use can slow down or even halt the whole system, harming all users who perform operations on the file system, not just the ones responsible for the problem.
In this thesis, we investigate if monitoring file system usage can help identify the causes of slowdowns and the users responsible for them.

The literature and professionals often refer to interaction with storage as I/O, an abbreviation for Input/Output.
Generally, I/O refers to communication between a computer and the outside world, but we often use it to describe interactions with a storage device.
A file system is a commonly used abstraction layer between the physical storage device and the user, but there are others, such as object storage.
The term storage I/O is agnostic about the underlying abstraction layer.
In this work, the I/O refers to storage I/O.

HPC is moving from computation-centric workloads to I/O-centric workloads.
Traditionally, we measure the performance of an HPC system in standard linear algebra operations per second, focusing on the processor and memory [@performance_linear_algebra; @linpack_benchmark].
<!-- A ranking is maintained on the TOP500 list [@top_500]. -->
However, storage is becoming increasingly important in HPC system due to data-intensive workloads, such as data science and machine learning, which relies on huge amounts of data.
The system must transport this data between main memory and storage, making I/O performance essential and problems from heavy I/O more common.
There are new benchmarks to measure I/O performance, such as the ones discussed in the IO500 benchmarks [@io_500_benchmark].
<!-- Ranking on IO500 list [@io_500]. -->
These reasons make studying storage and I/O performance in HPC systems necessary.
Researchers, developers, and operators actively try to find ways to improve parallel file systems [@io_load_balancing; @efficient-metadata-indexing] and develop alternative storage solutions for HPC [@daos_and_friends; @object_centric_data].

Since parallel file systems are shared, and heavy usage can cause problems, educating users about how to use them correctly is crucial.
Many HPC facilities have guidelines for performing file I/O on high-performance clusters.
Texas Advanced Computing Center (TACC) has collected many of these guidelines and tools to help implement them into the paper [@tacc-io-guideline].
Guidelines focus on avoiding overburdening the parallel file system with bad practices and moving the heavy load to local temporary storage away from the shared file system.
Problematic practices and solutions for them include the following:

* Using many small files instead of a few large files.
  Accessing the same amount of data from many small files than fewer large files requires more file system operations.

* Having too many files in a single directory instead of using subdirectories or local temporary storage.

* Not striping large files; we should stripe large files.
  Striping a file refers to storing consecutive segments of a large file into multiple storage devices for improved performance.
  Automatic striping or tools to help users to stripe files with the correct stripe count may alleviate this problem.

* Performing suboptimal file I/O patterns.
  For example, patterns that create large amounts of unnecessary file system operations, such as repeatedly opening and closing the same file.

* Performing high-frequency file I/O instead of keeping data in memory or limiting the I/O frequency.

* Accessing the same file from multiple processes simultaneously instead of creating copies of the file or using parallel I/O libraries.

* Overlooking I/O patterns workloads; we should use I/O profiling tools.

As a solution, we can also use tools for throttling the I/O rate of jobs performing heavy I/O [@ooops].

Monitoring file system performance is also essential for identifying when and why problems occur.
The authors in [@year-in-life-of-parallel-file-system] used multiple I/O performance probes to measure the performance of a parallel file system of multiple computer clusters for over a year at the National Energy Research Scientific Computing Center (NERSC) and Argonne Leadership Computing Facility (ALCF).
They applied statistical methods and time series analysis to identify variations in long and short-term performance trends.
For example, short transient issues differ from long persistent ones, and the baseline performance can change over time.
Their work provides insight into understanding the behavior of parallel file systems, monitoring and analysis techniques of parallel file systems, and how to improve them.
<!-- They also mentioned different monitoring levels, such as application-level monitoring, file system workload monitoring, file system capacity and health monitoring, resource manager monitoring, and tracking changes and updates to the system. -->

However, performance monitoring is not enough to identify who is causing problems; we need fine-grained file system usage monitoring.
In a study [@understanding-io-behaviour] conducted by Lawrence Livermore National Laboratory (LLNL), the authors collected and analyzed statistics of file system usage from two clusters to obtain insights for improving storage design.
Their methods included analyzing general I/O share and read versus write patterns of a large number of jobs over a one-year duration.
Other computing centers, such as the Oak Ridge Leadership Computing Facility (OLFC)  and National Computational Infrastructure (NCI), have also employed file system usage monitoring [@lustre-job-stats-metric-aggregation; @fine-grained-file-system-monitoring]
A discussion with the admins of Aalto Scientific Computing (SciComp) revealed that they use a commercial product, the *View for ClusterStor* from Cray Inc [@view-for-clusterstor], for monitoring.
Another example of a commercial product for monitoring is *DDN Insight* [@ddn-insight] from DataDirect Networks (DDN).

In this work, we experiment with the file system usage monitoring on the *Puhti* cluster at CSC.
Currently, we have only system-level load monitoring from processor usage and job information from the workload manager without any metrics from the file system usage.
However, load monitoring only tells us if file system problems occur but do not identify their causes.
Currently, administrators have to determine the causes manually.
However, the problem often disappears before they have identified the actual cause.
Active monitoring of file system usage should help system administrators to identify the causes and take action as the issues occur, not afterward.
It should also reduce the amount of manual work involved.

Puhti uses the Lustre parallel file system.
We can collect fine-grained statistics of file system usage with Lustre Jobstats.
In practice, it means various file operations statistics with job, user, Lustre client, and Lustre target information.
We can query these statistics at regular intervals to obtain time series data, which we can process into file system metrics.
Our objective is to obtain insights and understand the causes of issues from these metrics using time series analysis and visualization techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.
Our goal is to create active monitoring and near real-time warning systems to identify users whose programs cause problems in the file system.
Real-time monitoring should provide valuable information for improving the usability and throughput of the system.

<!--
Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.
-->

<!-- outline -->
The thesis is structured as follows.
In Section \ref{high-performance-computing}, we present a general overview of high-performance computing and related software.
Section \ref{puhti-cluster-at-csc} covers the configuration of the Puhti cluster.
We describe the monitoring system, such as how we collect data, what data we collect, how we store it, and how we analyze the data in Section \ref{monitoring-and-analysis}.
We present our result in Section \ref{results}.
We conclude by discussing what we accomplished in this work and ideas for future work in Section \ref{conclusion}.


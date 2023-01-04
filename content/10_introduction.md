\clearpage

# Introduction
<!-- TODO: add a figure to the introduction (monitoring, parallel file system) -->

Persistent data storage is an essential part of a computing system.
Many high-performance computing (HPC) systems, typically computer clusters, rely on a global, shared, parallel file system for large storage capacity and bandwidth.
A shared file system is available across the entire system, making it user-friendly but prone to problems from heavy use.
Such use may lead to congestion in a parallel file system, which can slow down or even halt the whole system, harming all users who perform operations on the file system, not just the ones responsible for the problem.
Heavy use may be intentional, such as data-intensive computing, or unintentional, such as unknowingly running a program that creates many temporary files.
In this thesis, we investigate if monitoring file system usage can help identify the causes of slowdowns and the users responsible for them.

The literature and professionals often refer to interaction with storage as I/O, an abbreviation for Input/Output.
Generally, I/O refers to communication between a computer and the outside world, but we often use it to describe interactions with a storage device.
A file system is a commonly used abstraction layer between the physical storage device and the user, but there are others, such as object storage.
The term storage I/O is agnostic about the underlying abstraction layer.
In this work, the I/O refers to storage I/O.

<!-- TODO: add reference, we have seen in practice -->
HPC is moving from computation-centric workloads to I/O-centric workloads.
Traditionally, we measure the performance of an HPC system in standard linear algebra operations per second, focusing on the processor and memory [@performance_linear_algebra; @linpack_benchmark].
<!-- A ranking is maintained on the TOP500 list [@top_500]. -->
However, storage is becoming increasingly important in HPC system due to data-intensive workloads, such as data science and machine learning, which relies on huge amounts of data.
The system must transport this data between main memory and storage, making I/O performance essential and problems from heavy I/O more common.
<!-- TODO: edit, which reasons -->
These reasons make studying storage and I/O performance in HPC systems necessary.
There are new benchmarks to measure I/O performance, such as the ones discussed in the IO500 benchmarks [@io_500_benchmark].
<!-- Ranking on IO500 list [@io_500]. -->
Researchers, developers, and operators actively try to find ways to improve parallel file systems [@io_load_balancing; @efficient-metadata-indexing] and develop alternative storage solutions for HPC [@daos_and_friends; @object_centric_data].

Since parallel file systems are shared, and heavy usage can cause problems, educating users about how to use them correctly is crucial.
Many HPC facilities have guidelines for performing file I/O on high-performance clusters.
<!-- TODO: guidelines explained below in bullets -->
Texas Advanced Computing Center (TACC) has collected many of these guidelines into the paper [@tacc-io-guideline].
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
Users can proactively throttle their workloads, or administrators can throttle jobs with heavy I/O without and avoid suspending these jobs.

Monitoring file system performance is also essential for identifying when problems occur.
By measuring and analyzing long-term I/O performance, we can detect variations in the trends at different timescales.
For example, a joint study by National Energy Research Scientific Computing Center (NERSC) and Argonne Leadership Computing Facility (ALCF) [@year-in-life-of-parallel-file-system] used multiple I/O performance probes to measure the performance of a parallel file system of multiple computer clusters for over a year.
They applied statistical methods and time series analysis to identify variations in long and short-term performance trends.
They showed that short transient issues differ from long persistent ones, and the baseline performance can change over time.
<!-- Their work provides insight into understanding the behavior of parallel file systems, monitoring and analysis techniques of parallel file systems, and how to improve them. -->
<!-- They also mentioned different monitoring levels, such as application-level monitoring, file system workload monitoring, file system capacity and health monitoring, resource manager monitoring, and tracking changes and updates to the system. -->

However, we need more than performance monitoring to identify who is causing problems; we need fine-grained file system usage monitoring to obtain specific information on how much each user, job, or node contributes to the total load.
Due to higher resolution, fine-grained monitoring produces more data than simpler aggregates and requires a time series database to store and query efficiently.
Regarding collecting fine-grained file system statistics, the Lustre parallel file system [@lustre-storage-architecture] has a feature called Lustre Jobstats [@lustre-monitoring-guide].
Earliest users of Lustre Jobstats include computing centers, such as the Oak Ridge Leadership Computing Facility (OLFC) [@lustre-job-stats-metric-aggregation] and National Computational Infrastructure (NCI) [@fine-grained-file-system-monitoring].
More recent studies have used Lustre Jobstats to collect long-term job-level I/O patterns to obtain insight for improving storage design [@understanding-io-behaviour].
There are also commercial products for monitoring that work with Lustre Jobstast, such as *View for ClusterStor* [@view-for-clusterstor] from Cray and *DDN Insight* [@ddn-insight] from DataDirect Networks (DDN).

<!-- A discussion with the admins of Aalto Scientific Computing (SciComp) revealed that they use a commercial product, the *View for ClusterStor* from Cray [@view-for-clusterstor] -->

<!-- TODO: introduce CSC -->
In this work, we experiment with the file system usage monitoring on the *Puhti* cluster at CSC.
Currently, we have only system-level load monitoring from processor usage and job information from the workload manager without any metrics from the file system usage.
However, load monitoring only tells us if file system problems occur but do not identify their causes.
Currently, system administrators have to determine the causes manually.
However, the problem often disappears before they have identified the actual cause.
Active monitoring of file system usage should help system administrators to identify the causes and take action as the issues occur, not afterward.
It should also reduce the amount of manual work involved.

Puhti relies on the Lustre parallel file system.
Therefore, we use Lustre Jobstats to collect fine-grained statistics of file system usage.
<!-- TODO: explain fine-grained in more general manner, remove or replace Lustre client and target, who did, from where to where -->
Fine-grained refers to collecting specific file operation statistics with the job, user, node, and Lustre target information.
Querying the statistics at regular intervals and computing rates produces a time series we can analyze.
Rates provide us with the average rate of change during an interval.
We aim to obtain insights and understand the causes of issues from these metrics using time series analysis and visualization techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.

Our goal is to create active monitoring and near real-time warning systems to identify users whose programs cause problems in the file system.
Real-time monitoring should provide valuable information for improving the usability and throughput of the system.
The scope of the thesis is to describe the monitoring system, the cluster we monitor, and the collected data on which we build the analysis and visualization from scratch.
The thesis advisor and system administrators were responsible for developing and deploying the monitoring system.

<!--
Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.
-->

<!-- TODO: discuss more about results -->
The thesis is structured as follows.
In Section \ref{high-performance-computing}, we present a general overview of high-performance computing and specific software related to high-performance clusters.
In Section \ref{puhti-cluster-at-csc}, we describe the configuration of the Puhti cluster from a storage perspective to understand the system we are monitoring.
Section \ref{monitoring-and-analysis} describes the monitoring system and analysis.
We explain how we collect data, what data we collect, how we store it, and how we analyze it.
Section \ref{results} presents the results from collecting and analyzing the monitoring data.
We explain issues with data quality and visualizations of the data we obtained.
Finally, Section \ref{conclusion} concludes the thesis by discussing what we accomplished in this work and ideas for future work.


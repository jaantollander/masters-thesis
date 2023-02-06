\clearpage

# Introduction
Persistent data storage is an essential part of a computing system.
Many high-performance computing (HPC) systems, typically computer clusters, rely on a global, shared, parallel file system for large storage capacity and bandwidth.
A shared file system is available across the entire system, making it user-friendly but prone to problems from heavy use.
Such use may lead to congestion in a parallel file system, which can slow down or even halt the whole system, harming all users who use the file system, not just the ones responsible for the problem.
Heavy use may be intentional, such as data-intensive computing, or unintentional, such as unknowingly running a program that creates many temporary files or a program that uses the file system for communication between processes.
In this thesis, we investigate whether monitoring file system usage can help identify the causes of slowdowns and the users responsible for them in a production system.

The professional literature typically refers to interaction with storage as *I/O*, an abbreviation for *Input/Output*.
Generally, I/O refers to communication between a computer and the outside world, but we often use it to describe interactions with a storage device.
A file system is a commonly used abstraction layer between the physical storage device and the user, but there are others, such as object storage.
The term *storage I/O* is agnostic about the underlying abstraction layer.
In this work, the I/O refers to storage I/O.

Contemporary HPC is moving from computation-centric workloads to I/O-centric workloads [TODO: reference needed, increase in data-intensive computing].
Traditionally, we measure the performance of an HPC system in standard linear algebra operations per second, focusing on the processor and memory [@performance_linear_algebra; @linpack_benchmark].
<!-- A ranking is maintained on the TOP500 list [@top_500]. -->
However, storage is becoming increasingly important in HPC system due to data-intensive workloads, such as data science and machine learning, which relies on huge amounts of data.
The system must transport this data between main memory and storage, making I/O performance essential and problems from heavy I/O more common.
The increasing demand for better I/O performance in HPC systems makes studying it necessary.
The HPC community has also established new benchmarks to measure I/O performance, such as the ones discussed in the IO500 benchmarks [@io_500_benchmark].
<!-- Ranking on IO500 list [@io_500]. -->
Research from various institutions and companies such as Oak Ridge National Laboratory, Lawrence Berkeley National Laboratory, Virginia Tech, Cray, and Seagate is actively finding ways to improve I/O performance in HPC.
For example, they research ways to improve parallel file systems [@io_load_balancing; @efficient-metadata-indexing] and develop alternative storage solutions [@daos_and_friends; @object_centric_data].

Since parallel file systems are shared, and heavy usage can cause problems, educating users about how to use them correctly is crucial.
Many HPC facilities have guidelines for performing file I/O on high-performance clusters.
For example, Texas Advanced Computing Center (TACC)'s guidelines [@tacc-io-guideline] advise how to avoid overburdening the parallel file system with bad practices and move the heavy load to local temporary storage away from the shared file system.
Furthermore, they list common bad practices and solutions for them, such as the following:

1) Using many small files instead of a few large files.
  Accessing the same amount of data from many small files than fewer large files requires more file system operations.
2) Having too many files in a single directory instead of using subdirectories or local temporary storage.
3) Not striping large files; we should stripe large files.
  Striping a file refers to storing consecutive segments of a large file into multiple storage devices for improved performance.
  Automatic striping or tools to help users to stripe files with the correct stripe count may alleviate this problem.
4) Performing suboptimal file I/O patterns.
  For example, patterns that create large amounts of unnecessary file system operations, such as repeatedly opening and closing the same file.
5) Performing high-frequency file I/O instead of keeping data in memory or limiting the I/O frequency.
6) Accessing the same file from multiple processes simultaneously instead of creating copies of the file or using parallel I/O libraries.
7) Overlooking I/O patterns workloads; we should use I/O profiling tools.

Another solution is to use tools for throttling the I/O rate of jobs performing heavy I/O [@ooops].
Users can proactively throttle their workloads, or administrators can throttle jobs with heavy I/O without and avoid suspending these jobs.

Even if users follow the guidelines, problems eventually occur.
To identify when they occur, we must actively monitor file system performance.
Furthermore, by measuring I/O performance and using statistical time-series analysis, we can identify variations in performance trends, such as *short-transient* or *long-persistent* ones, and changes in baseline performance over time [@year-in-life-of-parallel-file-system].
However, we need more than performance monitoring to identify who or what is causing problems in a parallel file system.
To identify causes, we can monitor file system health, capacity, and usage, track system changes, and use data from the resource manager.
This thesis focuses on fine-grained file system usage monitoring to identify the causes of short-transient problems.
*Fine-grained* refers to collecting statistics of each file system operation to identify who performs the operations, from which node, and to which storage unit.
Fine-grained monitoring shows us detailed file system behavior instead of a single aggregate of its performance.

Problems from parallel file system usage concern the high-performance clusters at *CSC -- IT Center for Science*, an organization that provides ICT services for higher education institutions, research institutes, culture, public administration, and enterprises in Finland.
[@about-csc]
<!-- These services include high-performance computing, cloud computing, data storage, network services, training, and technical support. -->
At the time of writing, CSC operates three high-performance clusters, *Puhti*, *Mahti*, and the pan-europian *LUMI*, which all use the *Lustre* parallel file system [@lustre-storage-architecture].
Especially the Puhti cluster is susceptible to service disruptions from heavy file system usage, which leads to lost productivity and billing units for the users.
We believe that monitoring file system usage will help us to identify the causes of the problems and take action faster to alleviate them.

Lustre has a feature called *Lustre Jobstats* [@lustre-monitoring-guide] for collecting file system usage statistics at a fine-grained level.
Early experimental monitoring with Jobstats includes [@lustre-job-stats-metric-aggregation; @fine-grained-file-system-monitoring].
More recently, Jobstats have been used to collect long-term, job-level I/O patterns for improving storage design [@understanding-io-behaviour].
We will use Jobstats to collect statistics at higher granularity than the previous studies.
Commercial monitoring products also work with Lustre Jobstats, such as View for ClusterStor [@view-for-clusterstor] and DDN Insight [@ddn-insight].
Unfortunately, these products did not meet our monitoring and analysis needs, which led us to develop a custom solution.

In this work, we monitor and analyze file system usage in the *Puhti* cluster.
Our long-term goal at CSC is to build active monitoring and near real-time warning systems to identify who and what causes problems in the file system.
This thesis takes steps towards achieving this goal.
<!-- Real-time monitoring should provide valuable information for improving the usability and throughput of the system. -->
Currently, Puhti has system-level load monitoring from processor usage, file system capacity monitoring, and job information from the workload manager, which cannot identify the causes of the problems.
When problems occur, system administrators have to determine the causes manually.
However, the problem often disappears before they have identified the actual cause.
Active monitoring of file system usage should help system administrators to identify the causes and take action as the issues occur, not afterward.
It should also reduce the amount of manual work involved.

The scope of the thesis is to describe the Puhti cluster, the monitoring system, details of the collected data, the data analysis methods we used, and the results from the analysis.
The thesis advisor and system administrators were responsible for developing, deploying, and maintaining the monitoring system on Puhti.
Their effort was instrumental in initiating the thesis work, collecting the data, and helping with writing the thesis.
The thesis's contributions are the data analysis methods and visualizations, which the thesis author built from scratch.

<!-- TODO: improve thesis outline based on the section contents -->
The thesis is structured as follows.
In Section \ref{high-performance-computing}, we present a general overview of high-performance computing and specific software related to high-performance clusters.
In Section \ref{puhti-cluster-at-csc}, we describe the configuration of the Puhti cluster from a storage perspective and explain the necessary system identifiers for fine-grained data.
In Section \ref{monitoring-system}, we describe the monitoring system and explain how we collect data, what data we collect, and how we store it.
Section \ref{results} presents methods and results from explorative data analysis on the collected monitoring data during this thesis.
We explore issues with data quality and how they affected the thesis work, provide visualizations and explanations of the monitoring data, demonstrate that we can find outliers from the data, and present ideas for future improvement in the analysis methods.
Section \ref{conclusion} concludes by discussing the general aspects of the thesis work, which thesis goals we accomplished, which ones we had to leave for future work, and perspectives for future work on monitoring file system usage.

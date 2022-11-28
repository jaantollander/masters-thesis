\newpage

# Introduction
File storage is an essential part of any computing system for persistent data storage.
Many large-scale computing systems, such as computer clusters, rely on a global, shared, parallel file system for large amounts of storage capacity and bandwidth.
This file system is available for all users on the whole system, making it user-friendly but prone to problems from heavy use or misuse.
Furthermore, these problems can noticeably slow down the whole system, harming all users, not just the users responsible for it.
In this thesis, we investigate if file system monitoring can effectively identify the causes of these issues and the users responsible for them in the *Lustre* parallel file system.

TODO: reference to Section \ref{high-performance-computing}

Previous work exists regarding issues and solutions for performing heavy file I/O on a Lustre file system.
The authors of [@tacc-io-guideline] discuss common issues related to heavy file I/O on a parallel file system, various novel tools designed to solve problems caused by heavy file I/O, and provide general guidelines for avoiding problems.
Problematic practices include using many small files instead of a few large files, too many files in a single directory, inappropriate striping, suboptimal file I/O patterns such as opening and closing the same file multiple times, performing unnecessary file I/O, and accessing the same file from multiple processes simultaneously.
They provide solutions for the problematic practices drawn from practical experience in operating systems at the *Texas Advanced Computing Center (TACC)*.

Previous work in monitoring and analyzing file system statistics exists.
For example, the authors of [@paul2020_1] collected and analyzed usage statistics of file system operations from two clusters in *Lawrence Livermore National Laboratory (LLNL)* over a long period to obtain insight for improving storage design.

Regarding developing and improving the performance of parallel file systems, the authors of [@paul2020_2] ...

To study the file system monitoring in practice, we deploy our monitoring system on the *Puhti* cluster at CSC and collect and analyze statistics.
We cover the configuration of the Puhti cluster in Section \ref{puhti-cluster-at-csc}.

Currently, there's only system-level load monitoring from processor usage and job information from job scheduler without any metrics from the file system usage.
However, load monitoring can only tell us if problems occur but not identify their causes.
To identify the causes, we need specific metrics of the file system usage.

The software that controls the file system keeps statistics of file system operations performed by different jobs.
We can query these statistics at regular intervals to obtain the file system metrics as a time series.
Our objective is to obtain insights and understand the causes of issues from these metrics using data visualization and analysis techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.
Our goal is to create active monitoring and near real-time warning systems to identify users whose programs use the file system in a problematic way.
We believe that real-time monitoring will provide valuable information for improving the usability and throughput of the system.

TODO: reference to Section \ref{monitoring-system} and \ref{analyzing-statistics}

Currently, when file system issues emerge, administrators have to determine the reason manually.
In many cases, the problem disappears before they have identified the actual cause.
With active monitoring, system administrators should be able to identify the causes and take action as the issues occur, not afterward.
It should also reduce the amount of manual work involved.

Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.

TODO: reference to Section \ref{results}


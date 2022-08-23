\newpage

# Introduction
> - *Introduction to the research topic*
> - *Problem description*
> - *Research objectives*
> - *Scope of the research*
> - *Length around 2 pages*

---

In this thesis, we investigate performance issues in a parallel file system of a computer cluster.
Notably, we examine issues related to file system usage of jobs, a term we use for the instances of programs run by users.
Due to the shared nature of the file system, performance issues can cause noticeable slow-down across the whole cluster, harming all users.
Specifically, we will explore these issues in the *CSC Puhti* [@cscpuhti], a computer cluster that runs lots of heterogenous, small to medium scale jobs from a large number of users.

Currently, there's only system-level load monitoring from processor usage and job information from job scheduler without any metrics from the file system usage.
However, load monitoring can only tell us if problems are occuring, but not identify their causes.
To identify the causes we need specific metrics of the file system usage.

The software that controls the file system keeps statistics of file system operations performed by different jobs.
We can query these statistics at regular intervals to obtain the file system metrics as a time series.
Our objective is to obtain insights and understand the causes of issues from these metrics using data analysis techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.
Our goal is to create active monitoring and near real-time warning systems to identify users whose programs use the file system in a problematic way.
We believe that real-time monitoring will provide valuable information for improving the usability and throughput of the system.

Currently, when file system issues emerge, administrators have to determine the reason manually.
In many cases, the problem disappears before they have identified the actual cause.
With active monitoring, system administrator should be able to identify the causes and take action as the issues occur, not afterwards.
It should also reduce the amount of manual work involved.

Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.


\newpage

# Introduction
In this thesis, we investigate performance issues in a parallel file system of a computer cluster.
Notably, we examine issues related to usage of the parallel file system of programs instances run by users, usually referred as jobs.
Due to the shared nature of the file system, performance issues can cause noticeable slow-down across the whole cluster, harming all users.

Issues related to usage of parallel file system are widely known.
[@tacc-io-guideline; @paul2020_1; @paul2020_2]

\textcolor{red}{
TODO: explain known issues and solutions related to usage of parallel file systems and previous work in file system monitoring
}

*CSC - The IT Center for Science* provides ICT services for higher education institutions, research institutes, culture, public administration and enterprises.
It is owned by the Finnish-state and higher education institutions.
These services include access to high-performance computing, cloud computing and data storage, as well as, training and technical support for using them.
CSC has two high-performance computer clusters, *Puhti* and *Mahti*.
Specifically, we will explore these issues in *Puhti*, a computer cluster that runs lots of heterogenous, small, medium and large scale jobs from a large number of users.
We focus on the *Puhti* cluster, explains its structure and the issues related the usage of the Lustre file system.

Currently, there's only system-level load monitoring from processor usage and job information from job scheduler without any metrics from the file system usage.
However, load monitoring can only tell us if problems are occuring, but not identify their causes.
To identify the causes we need specific metrics of the file system usage.

The software that controls the file system keeps statistics of file system operations performed by different jobs.
We can query these statistics at regular intervals to obtain the file system metrics as a time series.
Our objective is to obtain insights and understand the causes of issues from these metrics using data visualization and analysis techniques.
Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage.
Our goal is to create active monitoring and near real-time warning systems to identify users whose programs use the file system in a problematic way.
We believe that real-time monitoring will provide valuable information for improving the usability and throughput of the system.

Currently, when file system issues emerge, administrators have to determine the reason manually.
In many cases, the problem disappears before they have identified the actual cause.
With active monitoring, system administrator should be able to identify the causes and take action as the issues occur, not afterwards.
It should also reduce the amount of manual work involved.

Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.


\newpage

# Introduction
- Introduction to the research topic 
- Problem description
- Research objectives
- Scope of the research

---

In this thesis, we investigate performance issues in a large parallel file system of a computer cluster. Particularly, we investigate issues related to file system usage of the programs run by users. Due to the shared nature of the file system, performance issues can cause noticeable slow-down across the whole cluster, which can have a negative effect on all users.

The software that controls the file system keeps count of how many file system operations different programs have performed since they started. We can query these counters at regular intervals to obtain the file system metrics as a time series. Our objective is to obtain insights and understanding of the causes of issues from these metrics using techniques for analysing time-series. Furthermore, we aim to develop tools for monitoring and analyzing the cluster's file system usage. Our goal is to develop an active monitoring and near real-time warning system to identity users whose programs use the file system in a problematic way.

Currently, there's only system-level load monitoring together with job information without any file system related metrics. When file system issues emerge, administrators have to determine the reason manually. In many cases the issue disappears before they have identified the actual cause. 

The monitoring will improve the usability and throughput of the system and make the work of system administrators easier.

[*Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.*]


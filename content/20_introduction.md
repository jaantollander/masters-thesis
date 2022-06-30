# Introduction
In this thesis, we investigate causes of performance issues in a large parallel file system of a computer cluster.

Our objective is to obtain insights and understanding of the causes by using a combination of various system and user level metrics.

We aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system. 

Additionally, we aim to develop tools for monitoring the system usage. Goal is to have active monitoring and near real-time warnings on problematic IO patterns of user jobs.

Currently there's only system-level load monitoring together with job information without any IO related metrics. When IO issues emerge, the reason is determined manually by administrators. In many cases the issue disappears before the actual cause has been identified.

Combining the job-level IO logs will give much more detailed information on the types of IO load that causes issues with the storage system. Furthermore, it should be possible to have near real-time monitoring of load with detailed information on performance critical jobs.

The monitoring will improve the usability and throughput of the system and make the work of system administrators easier.

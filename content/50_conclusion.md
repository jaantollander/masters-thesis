\clearpage

# Conclusion
<!-- We need to describe what we did and achieved and relate to the goals set in the Introduction. -->

 <!-- Describe general aspects of the thesis work and process -->
The challenges in this thesis work were primarily practical engineering rather than deep theoretical ones.
We collected, stored, and analyzed large amounts of data, made installations to a live system requiring system admins' intervention, and had issues with software from a third-party vendor.

<!-- Describe the thesis work -->
The thesis explored monitoring and analyzing the usage of a parallel file system in the Puhti cluster.
Our goal was to find out whether monitoring could help us to identify slowdowns and their causes.
We explained the basic building blocks of a high-performance computing system [from a storage perspective].
We covered the configuration of the Puhti cluster at CSC from a storage perspective.
We developed a monitoring system, deployed it on the Puhti cluster, and collected file system data.
During the thesis work, we uncovered issues with data quality.
By analyzing raw data, we identified that the issue was caused by a bug in the Lustre jobstats feature that we used for collecting the data.
Due to the issues, we had to modify the monitoring system and data analysis workflows to correct the issues to the extent possible and discard previous data that would have been useful in our analysis.
Consequently, we lost valuable time and effort and only met some of the original goals set for the thesis, such as identifying users who perform heavy usage on the file system but not others, such as automated, real-time analysis of the monitoring data and warning system of the caused of slowdowns in the cluster.
Fortunately, we obtained data that we believed to be reliable and used it for analysis and visualization and to obtain insights for future parallel file system usage monitoring.
The results demonstrate different usage patterns and total rates for all the monitored file system operations.
The data demonstrate that an individual user can cause the majority of file system operations at a given time.

<!-- Future work and possibilities -->
Problems from parallel file system usage will not disappear in the future due increase demand for data-intensive computing.
We hope to fix these problems and obtain reliable data in the future.
The ultimate goal is to provide real-time monitoring, visualization, and reporting deployed on a live system that administrators can use to identify if a slowdown is caused by file system usage and who is causing it.
<!-- Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system. -->

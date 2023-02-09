\clearpage

# Conclusion
<!-- We need to describe what we did and achieved and relate to the goals set in the Introduction. -->

 <!-- Describe general aspects of the thesis work and process -->
The challenges in this thesis work were primarily practical engineering rather than deep theoretical ones.
We collected, stored, and analyzed large amounts of data, made installations to a live system requiring system admins' intervention, and had issues with software from a third-party vendor.
Despite the challenges, we were able to obtain meaningful results that we believe will benefit the future research and development of monitoring parallel file system usage.
Furthremore, these efforts take us closer to achieving the long-term goal at CSC is to build real-time monitoring, visualization, and reporting deployed on a live system that administrators can use to identify if a slowdown is caused by file system usage and who is causing it.

<!-- Describe the thesis work -->
In summary, the thesis explored monitoring and analyzing the usage of a parallel file system in the Puhti cluster.
Our goal was to find out whether monitoring could help us to identify slowdowns and their causes.
We explained the basic building blocks of a high-performance computing system and covered the configuration of the Puhti cluster at CSC from a storage perspective.
We developed a monitoring system, deployed it on the Puhti cluster, and collected file system usage data.

During the thesis, we uncovered issues with data quality.
By analyzing raw data, we identified that the issue was caused by a bug in the Lustre Jobstats that we used for collecting the data.
Due to the issues, we had to modify the monitoring system and data analysis workflows to correct the issues to the extent possible and discard previous data that would have been useful in our analysis.
Consequently, we lost valuable time and effort and only met some of the original goals set for the thesis.

Due to unreliable data, we did not find it feasible to build an automated monitoring and analysis system that would identity the causes of slowdowns in the cluster in real-time.
Fortunately, we obtained enough data that we believed to be reliable to use for analysis and visualization and obtained insights for future parallel file system usage monitoring.
We were able to identify users who perform heavy usage on the file system from this monitoring data.
The results demonstrate different usage patterns and total rates for all the monitored file system operations and that an individual user can cause the majority of file system operations at a given time.
<!-- TODO: refer to the future work -->
Finally, we discussed ideas for future analysis methods that we can try when we have reliable monitoring data from a longer period.

<!-- Future work and possibilities in general -->
We expect problems from parallel file system usage to increase in the future at CSC due to the increase demand for data-intensive computing.

<!-- Additionally, we aim to provide information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system. -->

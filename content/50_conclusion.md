\clearpage

# Conclusion
The challenges in this thesis work were primarily practical engineering rather than deep theoretical ones.
We collected, stored, and analyzed large amounts of data; we made installations to a live system requiring system admins' intervention, and we had issues with software from a third-party vendor.
Despite the challenges, we obtained meaningful results that will benefit future research and development of monitoring parallel file system usage.
Furthermore, these efforts take us closer to achieving the long-term goal at CSC is to build real-time monitoring, visualization, and reporting deployed on a live system that administrators can use to identify if a slowdown is caused by file system usage and who is causing it.
Also, we believe that file system usage and I/O metrics could provide helpful information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.

The thesis explored monitoring and analyzing the usage of a parallel file system in the Puhti cluster.
Our goal was to determine whether monitoring could help us identify slowdowns and their causes.
We explained the basic building blocks of a high-performance computing system and covered the configuration of the Puhti cluster at CSC from a storage perspective.
We developed a monitoring system, deployed it on the Puhti cluster, and collected file system usage data.

During the thesis, we uncovered issues with data quality caused by a bug in Lustre Jobstats and potentially by configuration or other issues in Puhti.
Due to the issues, we had to modify the monitoring system and data analysis workflows to correct the issues to the extent possible and discard previous data that would have been useful in our analysis.
Consequently, we lost valuable time and effort and only met some of the original goals for the thesis.

Due to unreliable data, we did not find it feasible to build an automated monitoring and analysis system to identify the causes of slowdowns in the cluster in real time.
Fortunately, we obtained enough data that we believe to be reliable for batch analysis and visualization.
The results from the analysis demonstrate different low-level file system usage patterns and high-level views of total rates for all the monitored file system usage statistics.
Furthermore, we demonstrate that we can identify users who cause large relative increases in I/O rates from our obtained data.
Finally, we discussed future ideas for building the automated, real-time analysis and warning system that we can try after we solve the data quality issues.
We believe that future work monitoring and understanding I/O behavior and performance in HPC systems is essential since I/O problems, such as those caused by parallel file system usage, will increase as high-performance computing becomes more data intensive.
\clearpage

# Conclusion
The challenges in this thesis work were primarily practical engineering rather than deep theoretical ones.
We collected, stored, and analyzed large amounts of data; we made installations to a live system requiring system admins' intervention, and we had issues with software from a third-party vendor.
Despite the challenges, we obtained meaningful results that will benefit future research and development of monitoring parallel file system usage.
Furthermore, these efforts take us closer to achieving the long-term goal at CSC is to build real-time monitoring, visualization, and reporting deployed on a live system that administrators can use to identify causes of slowdowns originating from parallel file system usage.
Also, file system usage and I/O metrics could provide helpful information that can guide future procurements and configuration changes such that the investments and modifications improve the critical parts of the storage system.

Concretely, we explored monitoring and analyzing the usage of Lustre parallel file system in the CSC's Puhti cluster.
We described the necessary details of a high-performance computing system, the Lustre parallel file system and the configuration of the Puhti cluster at CSC for collecting fine-grained file system usage statistics with Lustre Jobstats.
We also described how our monitoring system works by running a monitoring client on each Lustre server to collect data from Lustre Jobtats and send it to the ingest server, which inserts the data into a time series database.
These descriptions will help us improve future versions of our monitoring system.

During the thesis, we uncovered issues with data quality caused by a bug in Lustre Jobstats and potentially by configuration or other issues in Puhti.
Due to the issues, we had to modify the monitoring system and data analysis workflows to correct the issues to the extent possible and discard previous data that would have been useful in our analysis.
Consequently, we lost valuable time and effort and only met some of the original goals for the thesis.
Unreliable data made it infeasible to build an automated monitoring and analysis system to identify the causes of slowdowns in the cluster in real-time.
Fortunately, we obtained enough data that was sufficiently reliable for explorative data analysis and visualization as a batch.

The results from the analysis demonstrate different low-level file system usage patterns and high-level views of total rates for all the monitored file system usage statistics during 24 hours of 2022-10-27.
Furthermore, we demonstrate that we can identify users who cause large relative increases in I/O rates from our obtained data.
When we solve data quality issues, we can use these results to guide our future attempts to build an automated, real-time analysis and warning system.
We discussed ideas of analysis methods we can try in the future, such as analyzing operations together and automatically identifying changes in I/O trends.
We believe that future work monitoring and understanding I/O behavior and performance in HPC systems is essential since I/O problems, such as those caused by parallel file system usage, will increase as high-performance computing becomes more data intensive.

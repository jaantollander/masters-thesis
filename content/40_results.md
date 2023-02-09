\clearpage

# Results
This section presents the results from analyzing the data obtained from monitoring file system usage on the Puhti cluster.
Unfortunately, due to issues with data quality from Lustre Jobstats on Puhti, we did not reach all the thesis goals set in Section \ref{introduction}.
We could not perform a reliable analysis of the monitoring data from the initial monitoring client and had to discard it.
Furthermore, the data quality issue prevented us from developing a reliable, automated analysis and visualization of the real-time monitoring data.
Also, we did not have time to gather enough reliable data to correlate file system usage with slowdowns after discarding the initial data.
In Subsection \ref{entries-and-issues}, we discuss the data quality issues regarding the entry identifiers and investigate the entry identifiers from a large sample of consecutive Jobstats outputs.

Later, we obtained new data from the modified monitoring client.
However, due to the nature of the issue, we had to discard some of the obtained data.
The remaining data seems plausible, and we derive insights from this data and formulate ideas for future work.
Regarding the research questions from Section \ref{introduction}, the data indicates that we can identify users who perform more file system operations than others on the cluster, often orders of magnitude more.
However, the data quality issues reduce the reliability of the identification.
We demonstrate different aspects of this data from compute nodes taken at 2-minute intervals for 24 hours on 2022-10-27.
We omitted data from login and utility nodes in this analysis due to a lack of time to verify the correctness of the data.
Subsection \ref{counters-and-rates} shows counter values and computed rates of three jobs to illustrate different I/O patterns.
In Subsections \ref{metadata-rates} and \ref{object-storage-rates}, we show the total rates of each operation for each Lustre target to visualize larger-scale I/O patterns across the whole data set.
Subsection \ref{identifying-heavy-io} shows how fine-grained measurements allow us to break the total rate down into its components which we can use to identify users who perform heavy I/O.
Figures demonstrate how a single user can perform the majority of a total load of a given file system operation.
In Subsection \ref{future-work}, we explore ideas for improving the analysis in the future.

We performed explorative data analysis on batches of monitoring data using the Julia language [@julia_fresh_approach; @julia_language] and tabular data manipulation tools from the DataFrames.jl [@julia_dataframes] package.
To visualize our results, we used Plots.jl [@julia_plots] with GR [@gr_framework] as the backend.
We obtained a database dump from a selected period into Apache Parquet files, a file format that can efficiently handle and compress tabular data.
We limited the file size to be manageable on a local computer by dumping data from different days to separate files.
We preprocessed the monitoring data by computing rates from the counter values and discarding unwanted data.
<!-- TODO: we used snapshot time as the timestamp and inferred the beginning of the time series -->
The processed data consists of rows of timestamp and metadata values and the average rate of each operation from the previous to the current timestamp.
The metadata values are categorical; that is, they take values from a fixed set of possible values, such as the names of Lustre targets from Table \ref{tab:lustre-servers-targets}, node names from Table \ref{tab:node-names}, valid user identifiers, and valid job identifiers.
We describe the theoretical aspects of computing rates from counters and sums and densities for rates in Appendix \ref{computing-and-aggregating-rates}.

\clearpage

# Results
This section presents the results from analyzing the data obtained from monitoring file system usage on the Puhti cluster.
Unfortunately, due to issues with data quality from Lustre Jobstats on Puhti, we did not reach all the thesis goals set in Section \ref{introduction}.
We could not perform a reliable analysis of the monitoring data from the initial monitoring client and had to discard it.
Furthermore, the data quality issue prevented us from developing a reliable, automated analysis and visualization of the real-time monitoring data.
Also, we could not correlate file system usage with slowdowns because we were not able to gather enough reliable data after having to discard the initial data.
In Subsection \ref{entries-and-issues}, we discuss issues related to entry identifiers and investigate the entry identifiers from a large sample of consecutive Jobstats outputs.

Later, we obtained new data from the modified monitoring client.
However, due to the nature of the issue, we had to discard some of the obtained data.
The remaining data seems plausible.
We use this data to derive insights for future work.
Regarding the research questions from Section \ref{introduction}, the data indicates that we can identify users who perform more file system operations than others on the cluster, often orders of magnitude more.
However, the data quality issues reduce the reliability of the identification.

We demonstrate different aspects of data from compute nodes taken at 2-minute intervals for 24 hours on 2022-10-27.
We omitted data from login and utility nodes in this analysis due to a lack of time to verify the correctness of the data.
Subsection \ref{counters-and-rates} shows raw counter values and computed rates of three jobs to illustrate different I/O patterns.
In Subsections \ref{total-rates-for-mdts} and \ref{total-rates-for-osts}, we show the total rates of each operation for each Lustre target to visualize larger-scale I/O patterns across the whole data set.
Finally, Subsection \ref{components-of-total-rates} shows how fine-grained measurements allow us to break the total rate down into its components.
Then we demonstrate how a single user can perform the majority of a total load of a given file system operation.


## Entries and issues

Format | Observed entry identifier
-|-
Correct | `wget.11317854`
Correct | `11317854:17627127:r01c01`
Missing job ID | `:17627127:r01c01`
Malformed | `wget`
Malformed | `wget.`
Malformed | `11317854`
Malformed | `11317854:`
Malformed | `113178544`
Malformed | `11317854:17627127`
Malformed | `11317854:17627127:`
Malformed | `11317854:17627127:r01c01.bullx`
Malformed | `:17627127:r01c01.bullx`
Malformed | `:1317854:17627127:r01c01`

: \label{tab:jobid-examples}
Examples of various observed entry identifiers.
The examples show correct entry identifiers, identifiers with missing job IDs, and various malformed identifiers.

We found that some of the observed entry identifiers did not conform to the format on the settings described in Section \ref{entry-identifier-format}.
Table \ref{tab:jobid-examples} demonstrates correct entry identifiers, an entry identifier with missing job ID, and different malformed entry identifiers we observed.

The first issue is missing job ID values.
Slurm sets a Slurm job ID for all non-system users running jobs on compute nodes, and the identifier should include it.
However, we found many entries from non-system users on compute nodes without a job ID.
Due to these issues, data from the same job might scatter into multiple time series without reliable indicators making it impossible to provide reliable statistics for specific jobs.
The issue might be related to problems fetching the environment variable's value.
This issue occurred in both MDSs and OSSs on Puhti.

The second, more serious issue is that there were malformed entry identifiers.
The issue is likely related to the lack of thread safety in the functions that produce the entry identifier strings in the Lustre Jobstats code.
A recent bug report mentioned broken entry identifiers [@jobid-atomic], which looked similar to our problems.
Consequently, we cannot reliably parse information from these entry identifiers, and we had to discard them, which resulted in data loss.
This issue occurred only in OSSs on Puhti.
We obtained feasible values for correct entry identifiers, but we are still determining if the integrity of the counter values is affected by this issue.

<!-- TODO: lines that do not show are zero -->

Next, we look at Figures \ref{fig:entry-ids-mdt} and \ref{fig:entry-ids-ost}, which show the number of entries per Lustre target and identifier format for system and non-system users in a sample of 74 Jobstats outputs taken every 2-minutes from 2022-03-04.
For non-system users, we see that the number of entry identifiers with missing job IDs is substantial compared to the number of correct identifiers.
We also observe that Jobstats systemically generates malformed identifiers on the OSSs.
In some conditions, it can create many of them.
Entries from non-system users are the most valuable ones for analysis.

We also see many values generated by only two system users, root and job control.
Entries from system users usually did not have a job ID as their processes do not run via Slurm, although sometimes they do have a job ID.
We found that they usually contain little valuable information; for example, many have a single `statfs` operation.
Regarding data accumulation, each entry corresponds to one row in the database.
Therefore, reducing the number of entries reduces storage size and speeds up queries and the analysis.
We should discard or aggregate statistics of system users to reduce the accumulation of unnecessary data.
In general, correct entry identifiers would reduce unnecessary data accumulation.

\definecolor{non-system-user}{rgb}{0.1216,0.4667,0.7059}
\definecolor{system-user}{rgb}{1.0,0.498,0.0549}

\newpage

![
The number of entries for each of the four MDTs during a sample of Jobstats outputs taken every 2 minutes during an interval on 2022-03-04.
Each subplot shows a different identifier format; line color indicates \textcolor{non-system-user}{non-system users} and \textcolor{system-user}{system users}; and each line shows a different MDT for a given user type.
We can see many missing job IDs compared to intact ones for non-system users, many entries for system users, and an unbalanced load between MDTs.
The first subplot shows the number of correct entries for login and utility nodes, and the second subplot shows them for compute nodes.
The third subplot shows the number of missing job IDs on compute nodes, which is substantial compared to the correct identifiers in the second subplot.
There are no malformed entries on MDTs.
We can see that only two of the four MDTs handle almost all of the metadata operations.
Of the two active MDTs, the first one seems to handle more operations than the second one, but their magnitudes seem to correlate.
The load across MDTs is unbalanced because MDTs are assigned based on the top-level directory, that is, to different storage areas, such as Home, Projappl, Scratch, and the usage of these storage areas varies.
We explained storage areas in Section \ref{system-configuration}.
\label{fig:entry-ids-mdt}
](figures/entry_ids_mdt.svg)

\newpage

![
The number of entries for each of the 24 OSTs during a sample of Jobstats outputs taken every 2 minutes during an interval on 2022-03-04.
Each subplot shows a different identifier format; line color indicates \textcolor{non-system-user}{non-system users} and \textcolor{system-user}{system users}; and each line shows a different OST for a given user type.
We can see many missing job IDs compared to intact ones for non-system users, many entries for system users, systematic generation of malformed entry identifiers, and a balanced load between OSTs.
The first subplot shows the number of correct entries for login and utility nodes, and the second subplot shows them for compute nodes.
The third subplot shows the number of missing job IDs on compute nodes, which is substantial compared to the correct identifiers in the second subplot.
The fourth subplot shows the number of malformed identifiers for all nodes.
We can see that Jobstats on Puhti systematically produce missing job IDs and malformed identifiers.
Furthermore, there is a large burst of malformed identifiers from 12.06 to 12.26, indicating that in some conditions, Jobstats produces large amounts of malformed identifiers.
It might be due to a heavy load on the OSS.
The load across OSTs is balanced because the files are assigned OSTs equally with round-robin unless the user explicitly overwrites this policy.
\label{fig:entry-ids-ost}
](figures/entry_ids_ost.svg)

\clearpage

## Counters and rates
<!-- TODO: add motivation, repeat what is in the Section -->
Figures \ref{fig:job-rate-1}, \ref{fig:job-rate-2}, and \ref{fig:job-rate-3} show different patterns of counter values and rates for `write` operations for different jobs during 24 hours of 2022-10-27.
The figures demonstrate the fine-grained nature of the monitoring data and entry resets discussed in Section \ref{monitoring-and-analysis}.
The x-axis displays time, and the y-axis display the accumulated amount of operations for counters and the operations per second for the rate.
Each line displays operations from one Lustre client to one Lustre Target.
The figures in this subsection display a single node job; thus, each line shows `write` operations from the same compute node to a different OST.
We say that a job is *active* during a period that performs any file system operations; otherwise, it is *inactive*.

![
The counter and rate of `write` operations from one job on a single compute node.
The top subplot shows the counter values, and the bottom subplot shows the rates computed from the counter values in the first plot.
The subplots share the same x-axis.
The counter values follow a typical saw-tooth pattern for almost linearly increasing counter values that reset periodically due to inactivity.
In the active periods, we see a higher write amount of writes in the beginning, then quite near constant write rate until the job becomes inactive.
The lines follow a similar pattern indicating that the job performs a similar write pattern for each OST except for the ones whose rate is near zero.
\label{fig:job-rate-1}
](figures/2022-10-27_ost_job_write_1.svg)

![
The counter and rate of `write` operations from one job on a single compute node.
The top subplot shows the counter values, and the bottom subplot shows the rates computed from the counter values in the first plot.
The subplots share the same x-axis.
The counter values increase almost linearly, indicating that the job performs writes consistently during the whole period.
The rate over the whole period is almost constant with some small fluctuations.
We can see that the job performs almost 75\% of the operations to one OST, almost 25\% to two other OSTs, and almost none to the others.
\label{fig:job-rate-2}
](figures/2022-10-27_ost_job_write_2.svg)

![
The counter and rate of `write` operations from one job on a single compute node.
The top subplot shows the counter values, and the bottom subplot shows the rates computed from the counter values in the first plot.
The subplots share the same x-axis.
One of the counter values increases in a wave-like pattern that resets periodically; the other counter seems to increase in a burst-like manner for short periods before resetting.
By looking at the rates, we can see that the rates fluctuate for all OSTs.
Furthermore, most of the time, the job performs writes to one OST and sometimes to multiple OSTs in a burst.
\label{fig:job-rate-3}
](figures/2022-10-27_ost_job_write_3.svg)


\clearpage

## Total rates for MDTs
<!-- TODO: add motivation, repeat what is in the Section -->
Figures \ref{fig:total-mdt-1}, \ref{fig:total-mdt-2}, \ref{fig:total-mdt-3}, \ref{fig:total-mdt-4}, \ref{fig:total-mdt-5}, \ref{fig:total-mdt-6}, and \ref{fig:total-mdt-7} show the total rates for all operations from compute nodes to each of four MDTs during 24 hours of 2022-10-27.
Comparing loads between MDTs is not interesting because Lustre assigned each storage area to one MDT.
We use a logarithmic scale due to large variations in the magnitude of the rates.
Because some rates in the plots are zero, but the logarithmic axis does contain zero, we omit zeros from the plot.
The plots share the same x-axis, making them easier to compare.

![
Total rates of `open` and `close` operations from compute nodes to each MDT.
We can see that the `open` rate is quite consistent, and `close` has a large drop around 12.00.
Large changes in rates are usually caused when a single job that performs heavy I/O stops.
We can also see that the rate of `close` is greater than the rate of `open`.
It is impossible to perform more `close` and `open` operations because we always need to open a file before closing it.
We suspect that Lustre clients cache `open` operations but not `close` operations, and Jobstats does not count cached operations.
Therefore, the close rate may look higher than the `open` rate from the statistics.
For example, if `open` is called multiple times with the same arguments Lustre client can serve it from the cache instead of having to request it from MDS; thus request is not recorded.
\label{fig:total-mdt-1}
](figures/2022-10-27_mdt_compute_1.svg)

![
Total rates of `mknod` and `unlink` operations from compute nodes to each MDT.
We can see the file creation rate by looking at the rate of `mknod` operations and the file removal rate by looking at the rate of `unlink` operations.
The values in these plots do not show large variations.
Elevated file creation and removal rates may indicate the creation of temporary files on the Lustre file system, which is undesirable.
\label{fig:total-mdt-2}
](figures/2022-10-27_mdt_compute_2.svg)

![
Total rates of `getattr` and `setattr` operations from compute nodes to each MDT.
We can see that the `getattr` rate is consistent, but the `setattr` has large spikes.
These rates indicate the frequency of querying and modifying file attributes, such as file ownership, access rights, and timestamps.
These rates may be elevated rates for example, due to the creation of temporary files.
In Figure \ref{fig:density-1}, we inspect the contribution of different users to the `setattr` rate on MDT.
\label{fig:total-mdt-3}
](figures/2022-10-27_mdt_compute_3.svg)

![
Total rates of `getxattr` and `setxattr` operations from compute nodes to each MDT.
We can see that `getxattr` rates are consistent throughout the period.
The magnitude of the `setxattr` rate is small, only a couple of operations per second, from 00.00 to 18.00, after which the rate falls to near zero.
\label{fig:total-mdt-4}
](figures/2022-10-27_mdt_compute_4.svg)

![
Total rates of `mkdir` and `rmdir` operations from compute nodes to each MDT.
Both rates are consistent throughout the period, and the magnitude is relatively small, for example, compared to file creation and removal in Figure \ref{fig:total-mdt-1}.
\label{fig:total-mdt-5}
](figures/2022-10-27_mdt_compute_5.svg)

![
Total rates of `rename` and `sync` operations from compute nodes to each MDT.
Both rates are consistent throughout the period, and the magnitude is relatively small.
\label{fig:total-mdt-6}
](figures/2022-10-27_mdt_compute_6.svg)

<!-- TODO: add samedir and crossdir renames to the rename plot? -->

![
Total rates of `link` and `statfs` operations from compute nodes to each MDT.
We can see that there are almost no `link` operations; hence the line is very sparse.
On the contrary, `statfs` operations seem consistent and appear on all MDTs.
\label{fig:total-mdt-7}
](figures/2022-10-27_mdt_compute_7.svg)


\clearpage

## Total rates for OSTs
Figures \ref{fig:total-ost-1}, \ref{fig:total-ost-2}, \ref{fig:total-ost-3}, \ref{fig:total-ost-4}, and \ref{fig:total-ost-5} show the total rates of all operations from compute nodes to each of 24 OSTs during 24 hours of 2022-10-27.
Since there are 24 OSTs, we can compare the variation of rate between OSTs and across time.
By default, Lustre aims to balance the load between OSTs by assigning files to them equally.
Significant differences between the rates of different OSTs mean that the load is unbalanced.
An unbalanced load may lead to congestion when others try to access the same OST.
We use a logarithmic scale due to large variations in the magnitude of the values.
All plots share the same x-axis, making them easier to compare.

<!-- TODO: use single color for all targets and use alpha, highlight one OST that we inspect in the next section, add references to those figures (also for MDTs), Each line is an OST, and there are 24 lines. -->

![
Total rates of `read` and `write` operations from compute nodes to each OST.
In the top subplot, we can see that the rate of `read` operations does not vary across OSTs from 00:00 to 07:00, but after 07:00, the variance increases.
Later in Figure \ref{fig:density-2}, in the next section, we explore the components of the total read rate on OST0001.
The bottom subplot shows us the rate of `write` operations which is smaller in magnitude.
The rate of most OSTs does not vary much, but individual OSTs deviate from the base load by order of magnitude.
The total write rate consists of individual `write` rates from many users' jobs, some of which are similar to the ones we saw in Figures \ref{fig:job-rate-1}, \ref{fig:job-rate-2}, and \ref{fig:job-rate-3}.
\label{fig:total-ost-1}
](figures/2022-10-27_ost_compute_1.svg)

![
Total rates of `readbytes` and `writebytes` operations from compute nodes to each OST.
We can see that the `readbytes` rate is mostly balanced over OSTs and consistent over the period, expect a few spikes and one long, heavy load from 9.00 to 14.00 to a single OST, which we inspect in more detail in Figure \ref{fig:density-3} in the next section.
Heavy load on a single OST indicates that a large file is not properly striped over multiple OSTs.
The `writebytes` rate is balanced over OSTs and consistent over the period with only a few spikes.
\label{fig:total-ost-2}
](figures/2022-10-27_ost_compute_2.svg)

![
Total rates of `punch` and `setattr` operations from compute nodes to each OST.
We can see that the `punch` rate spikes periodically simultaneously for all OSTs.
The `setattr` rate is very low and does not exhibit interesting patterns.
\label{fig:total-ost-3}
](figures/2022-10-27_ost_compute_3.svg)

![
Total rates of `quotactl` and `sync` operations from compute nodes to each OST.
We can see that the `quotactl` rate looks well balanced between OSTs, compared to other rates, such as `read` and `write` rates in Figure \ref{fig:total-ost-1}, likely because it does not operate on specific files, users cannot easily perform a different amount of `quotactl` operations of different OSTs.
The `sync` rate is very low and does not exhibit interesting patterns.
\label{fig:total-ost-4}
](figures/2022-10-27_ost_compute_4.svg)

![
Total rates of `getinfo` and `setinfo` operations from compute nodes to each OST.
Both rates are very low and do not exhibit interesting patterns.
\label{fig:total-ost-5}
](figures/2022-10-27_ost_compute_5.svg)

\clearpage


## Components of total rates
<!-- TODO: add motivation, repeat what is in the Section -->
Obtaining meaningful information visually from graphs with many time series is challenging because they tend to overlap.
To remedy this situation, we can use a density plot.
A density plot is a statistical plot that shows how many time series has a value in a specific range, called a bucket, at a particular time, but omits information about individual time series.
We can use the density plot to distinguish differences, such as whether an increase in total rate is due to a small number of users performing a high rate of operations or a large number of users performing a low rate of operations.
We can also use the information from a density plot to obtain time intervals and value ranges to filter original data.
The density plot is a heatmap consisting of time on the x-axis, buckets on the y-axis, and color on the z-axis.
The color indicates how many values fall into the bucket at a given time.
We can increase the resolution of a density plot by decreasing the sizes of the buckets and vice versa.
We determine a *threshold* between the average and outlier behavior such that the *average behavior*, with many small values, is below the threshold and the *outlier behavior*, with a few large values, is above the threshold.

<!-- TODO: we determine the threshold from the density plot, and we can tune the resolution -->
<!-- TODO: plots show one iteration of the process in \ref{analyzing-statistics} -->

Figures \ref{fig:density-1}, \ref{fig:density-2}, and \ref{fig:density-3} visualize the user-level behavior of a specific operation from compute nodes to a specific Lustre target.
Each figure consists of three subplots.
The top subplot shows the total rate, the middle subplot shows the total rates of each user, and the bottom subplot shows the density plot of the total rates of each user.
We use a logarithmic scale for the density due to the significant variations in the magnitude of the values and omit zeros from the plot.
In the density plot, lighter color indicates more users, a darker color indicates fewer users, and no color indicates zero users.

<!-- TODO: resolution of density in figures, base $10$ -->

<!--
We can also see general usage trends.
The base load mostly stays the same, although a few more users perform read operations from around 7.00 to 17.00 UTC, corresponding to daytime in Finland (10.00 to 20.00).
We can perform a similar analysis based on job ID or node name.
-->

<!-- TODO: highlight an individual line from the middle graph? -->

![
Decomposition of a total `setattr` rate from compute nodes to `scratch-MDT0000` during 24 hours of 2022-10-27.
We can visually determine a threshold between average and outlier behavior at $10^1.$
We can see two distinct patterns compared to the average behavior; many high spikes and three less intense bursts.
\label{fig:density-1}
](figures/2022-10-27_mdt0000_compute_setattr.svg)

![
Decomposition of a total `read` rate from compute nodes to `scratch-OST0001` during 24 hours of 2022-10-27.
We can visually determine a threshold between average and outlier behavior at $10^2.$
We can see that individual users cause bursts in the rate.
\label{fig:density-2}
](figures/2022-10-27_ost0001_compute_read.svg)

![
Decomposition of a total `readbytes` rate from compute nodes to `scratch-OST0004` during 24 hours of 2022-10-27.
We can visually determine a threshold between average and outlier behavior at $10^8.$
We can see that a single user caused a large increase in the rate between 9:00 and 14:00.
\label{fig:density-3}
](figures/2022-10-27_ost0004_compute_readbytes.svg)


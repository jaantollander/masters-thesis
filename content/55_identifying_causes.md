\clearpage

## Identifying causes of changes in I/O trends
<!-- TODO: add motivation, repeat what is in the Section -->
As discussed in Section \ref{monitoring-system}, fine-grained file system usage monitoring produces data that contains multiple time series and we identify each time series by a unique combination of metadata values.
As previous results demonstrate, we can inspect the data in a high-level view as a sum of many time series or in a low-level, fine-grained view as individual time series which form the components of the sum.
Our goal is to find changes in trends from the high-level view and the causes for the changes in trends from the low-level view.
Especially, we care about identifying causes for large increases in the I/O rates.

Because the fine-grained view consist of many time series, we compute a *density* to obtain information about the composition of sum at each timestamp.
Density tells us how many time series have a value in a specific range, called a *bucket*, at a particular time but omits information about individual time series.
Importantly density allows us to distinguish differences such as whether an increase in sum rate is due to a small number of large components or a large number of small components.

We explore a part of the data set visually using Figures \ref{fig:density-1}, \ref{fig:density-2}, and \ref{fig:density-3}.
We demonstrate a process of identifying users who cause large relative increases in I/O rates.
Each figure consists of three subplots.
The *top subplot* demonstrates the high-level trend by showing the total rate, that is, the sum of rates from all users.
We use it to identify periods where trends change, specifically the large relative increases.
The *middle subplot* demonstrates a more fine-grained view by showing the rate of each user, that is, the components of the total rate from the top subplot.
We analyze them to understand user-level causes of changes in the total rate.
The *bottom subplot* shows the density computed from the values seen in the middle subplot.
We use the density plots to analyze how many users perform I/O rate in specific range.
Specifically, we look at the bucket at the top of the plot to see how many users perform large I/O rates relative to others.
To identify a set of users, we filter the data set by using the time period and value range as conditions obtained from the subplots and look at the unique set of user metadata values.

We use a logarithmic scale for the density due to the significant variations in the magnitude of the values and omit zeros from the plot.
We plot densities as heatmaps consisting of time on the x-axis, buckets on the y-axis, and color on the z-axis.
In the density plot, lighter color indicates more users, a darker color indicates fewer users, and no color indicates zero users.
The resolution of the density plots, that is, the upper and lower bounds of the buckets, uses a logarithmic scale in base $10.$

<!--
We use density to determine a threshold between light I/O and heavy I/O.
We assume that heavy I/O is rarer than light I/O so that we can select a threshold with lots of light I/O below the threshold and a little heavy I/O above it.
We determine a threshold visually from the density plot.
We aimed to set the resolution of the density as low as possible such that find could still find a clear threshold.
We decrease the resolution of a density by increasing the sizes of the buckets.
To identify the causes of heavy I/O, we can filter the data using the threshold as a condition and look at the metadata values.
(We can quantify the threshold by counting how many users are below versus above the threshold in a given period.)
-->

<!--
A simple method for identifying heavy I/O from the data of a specific operation is to start from a lower resolution, high-level view, then select a subset of the data based on the view and increase the resolution on the subset, and repeat.
Here is an example of the process:
First, we select an operation and the initial data, such as the data for the `write` operation from compute nodes to a specific OST.
Then, we compute a density with a chosen resolution of the total rate over a chosen categorical value.
For example, we can choose the user ID as the categorical value and set the density resolution to exponentially increasing bucket size.
Next, we inspect the density plot, determine a time range and value threshold, and then filter the data using these values.
Finally, we either repeat the process by choosing a different categorical value and resolution or stop if we have identified the causes of heavy I/O.
-->

![
Decomposition of a total `setattr` rate from compute nodes to `scratch-MDT0000` during 24 hours of 2022-10-27.
We can visually determine a threshold between light and heavy I/O at $10^1$ operations per second.
We can see two heavy I/O patterns compared to the many light I/O patterns; many intense spikes and three less intense bursts.
\label{fig:density-1}
](figures/2022-10-27_mdt0000_compute_setattr.svg)

![
Decomposition of a total `read` rate from compute nodes to `scratch-OST0001` during 24 hours of 2022-10-27.
We can visually determine a threshold between light and heavy I/O at $10^2$ operations per second.
After 13:00, we see many bursts of heavy I/O caused by two users.
\label{fig:density-2}
](figures/2022-10-27_ost0001_compute_read.svg)

![
Decomposition of a total `readbytes` rate from compute nodes to `scratch-OST0004` during 24 hours of 2022-10-27.
We can visually determine a threshold between light and heavy I/O at $10^8$ bytes per second.
The figure shows us two heavy I/O patterns: one long, intense burst and one short, less intense burst.
We can see that a single user caused a long, intense burst, over a gigabyte ($10^9$ bytes) per second, between 9:00 and 14:00.
The shorter, less intense burst, from 9:00 to 10:00, is hundreds of megabytes ($10^8$ bytes) per second.
\label{fig:density-3}
](figures/2022-10-27_ost0004_compute_readbytes.svg)


\clearpage

## Identifying heavy I/O
<!-- TODO: add motivation, repeat what is in the Section -->
As discussed in Section \ref{monitoring-system}, fine-grained file system usage monitoring produces multiple time series, that is, rates from the monitoring data.
We have one time series for each time series identifier consisting of the metadata values.
To identify heavy I/O, we determine a *threshold between light and heavy I/O* by analyzing multiple time series.
We assume that heavy I/O is rarer than light I/O so that we can select a threshold with lots of light I/O below the threshold and a little heavy I/O above it.

We compute a *density* over time to obtain information from many time series.
Density is a statistical method that tells us how many time series have a value in a specific range, called a *bucket*, at a particular time but omits information about individual time series.
For example, we can use the density to distinguish differences, such as whether an increase in total rate is due to a small number of users performing a high rate or a large number of users performing a low rate of a specific operation.
Then, we use a *heatmap* to visualize the density and a heatmap to determine a threshold visually.
We aimed to set the resolution of the density as low as possible such that find could still find a clear threshold.
We decrease the resolution of a density by increasing the sizes of the buckets and vice versa.
To identify the causes of heavy I/O, we can filter the data using the threshold as a condition and look at the metadata values.

We demonstrate this process in Figures \ref{fig:density-1}, \ref{fig:density-2}, and \ref{fig:density-3}.
Each figure consists of three subplots.

1) The top subplot shows the total rate of a specific operation on a specific Lustre target.
It demonstrates the general trends.
2) The middle subplot breaks the total rate into the rates of each user.
It demonstrates the granular user-level view.
3) The bottom shows the density of the rates per user.
We use it to determine the threshold.

We use a logarithmic scale for the density due to the significant variations in the magnitude of the values and omit zeros from the plot.
We plot densities as heatmaps consisting of time on the x-axis, buckets on the y-axis, and color on the z-axis.
In the density plot, lighter color indicates more users, a darker color indicates fewer users, and no color indicates zero users.
The resolution of the density plots, that is, the upper and lower bounds of the buckets, uses a logarithmic scale in base $10.$

<!-- General idea behind the data analysis -->
<!-- TODO: generally the method work as follows ... -->
<!--
A simple method for identifying heavy I/O from the data of a specific operation is to start from a lower resolution, high-level view, then select a subset of the data based on the view and increase the resolution on the subset, and repeat.
Here is an example of the process:
First, we select an operation and the initial data, such as the data for the `write` operation from compute nodes to a specific OST.
Then, we compute a density with a chosen resolution of the total rate over a chosen categorical value.
For example, we can choose the user ID as the categorical value and set the density resolution to exponentially increasing bucket size.
Next, we inspect the density plot, determine a time range and value threshold, and then filter the data using these values.
Finally, we either repeat the process by choosing a different categorical value and resolution or stop if we have identified the causes of heavy I/O.
-->

<!--
We can also see general usage trends.
The base load mostly stays the same, although a few more users perform read operations from around 7.00 to 17.00 UTC, corresponding to daytime in Finland (10.00 to 20.00).
We can perform a similar analysis based on job ID or node name.
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


\clearpage

## Identifying heavy I/O
<!-- TODO: add motivation, repeat what is in the Section -->
Fine-grained file system usage monitoring produces data with multiple overlapping time series.
We can obtain meaningful information visually from a graph with many time series using a density plot.
A density plot is a statistical plot that shows how many time series has a value in a specific range, called a bucket, at a particular time but omits information about individual time series.
We can increase the resolution of a density plot by decreasing the sizes of the buckets and vice versa.
We can use the density plot to distinguish differences, such as whether an increase in total rate is due to a small number of users performing a high rate or a large number of users performing a low rate of a specific operation.

Furthermore, we can visually determine a *threshold* between the *light I/O* and *heavy I/O* from a density plot.
We should select a threshold such that the light I/O, with typically many small values, is below the threshold, and the heavy I/O, with typically a few large values, is above the threshold.
We should set the resolution as low as possible to find a clear threshold; if we cannot, we should increase the resolution of the density.
We can use the threshold as a condition for filtering the data.

<!-- General idea behind the data analysis -->
A simple method for identifying heavy I/O from the data of a specific operation is to start from a lower resolution, high-level view, then select a subset of the data based on the view and increase the resolution on the subset, and repeat.
Here is an example of the process:

* First, we select an operation and the initial data, such as the data for the `write` operation from compute nodes to a specific OST.
* Then, we compute a density with a chosen resolution of the total rate over a chosen categorical value.
For example, we can choose the user ID as the categorical value and set the density resolution to exponentially increasing bucket size.
* We can inspect the density plot, determine a time range and value threshold, and then filter the data using these values.
* Finally, we either repeat the process by choosing a different categorical value and resolution or stop if we have identified the causes of heavy I/O.

<!-- TODO: explain how figures relate to the above process -->
Figures \ref{fig:density-1}, \ref{fig:density-2}, and \ref{fig:density-3} visualize the user-level behavior of a specific operation from compute nodes to a specific Lustre target.
Each figure consists of three subplots.
The top subplot shows the total rate, the middle subplot shows the total rates of each user, and the bottom subplot shows the density plot of the total rates of each user.
We use a logarithmic scale for the density due to the significant variations in the magnitude of the values and omit zeros from the plot.
We plot densities as heatmaps consisting of time on the x-axis, buckets on the y-axis, and color on the z-axis.
In the density plot, lighter color indicates more users, a darker color indicates fewer users, and no color indicates zero users.
The resolution of the density plots, that is, the upper and lower bounds of the buckets, uses a logarithmic scale in base $10.$

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


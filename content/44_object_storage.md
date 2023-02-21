\clearpage

## Object storage rates
We explore trends of different object storage operations by visualizing the data we obtained from object storage servers.
Figures \ref{fig:total-ost-1}, \ref{fig:total-ost-2}, \ref{fig:total-ost-3}, \ref{fig:total-ost-4}, and \ref{fig:total-ost-5} show the total rates of all operations from compute nodes to each of 24 OSTs during 24 hours of 2022-10-27.
Since there are 24 OSTs, we can compare the variation of rate between OSTs and across time.
By default, Lustre aims to balance the load between OSTs by assigning files to them equally.
Significant differences between the rates of different OSTs mean that the load is unbalanced.
An unbalanced load may lead to congestion when others try to access the same OST.
We use a logarithmic scale due to large variations in the magnitude of the values.
All plots share the same x-axis, making them easier to compare.

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


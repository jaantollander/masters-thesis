\clearpage

## Metadata rates
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

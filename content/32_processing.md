\newpage

# Processing statistics
## Computing rates of change
> TODO: add plot of raw counter values and computed rate of change, generate fake data

For each unique identifier, each counter value $v\in\mathbb{R}$ such that $v\ge 0$ of an operation along time $t\in\mathbb{R}$ form a time series.
Given two points consequtive points in the time series, $(t, v)$ and $(t^\prime, v^\prime)$ where $t < t^\prime,$ we can calculate the *interval length* as $\Delta t > 0$ and *number of operations* $\Delta v > 0$ during the interval.
The interval length is

$$\Delta t = t^{\prime} - t.$$

If $v^\prime \ge v$, the previous counter value is incremented, and we have $\Delta v = v^\prime - v.$
Otherwise, if $v^\prime < v$, the counter has reset and the previous counter value is implicitly zero, and we have $\Delta v = v^\prime - 0.$
Combined, we can write

$$\Delta v = 
\begin{cases}
v^{\prime} - v, & v^{\prime} \ge v \\
v^{\prime}, & v^{\prime} < v
\end{cases}.$$

Then, we can calculate the *average rate of change* during the interval for each operation as

$$r=\Delta v / \Delta t.$$

If a particular `job_id` has not yet performed any operations, its counters contain implicit zeros, that is, they not in the output of the statistics.
In these cases, we can infer the *initial counter* $(t_0, v_0)$ where $v_0=0$ and set $t_0$ to the timestmap of last recording interval.
For the first recording interval, we cannot infer $t_0$ and we need to discard the initial counter.
The *observed counters* are $(t_1,v_1),...,(t_n,v_n),$ where $n\in\mathbb{N}.$
Then, given a series of counter values

$$(t_0, v_0), (t_1, v_1), (t_2, v_2), ..., (t_{n-1}, v_{n-1}), (t_n, v_n),$$

we can compute the series of average rates of change $r_i$ in the interval $[t_i,t_{i+1})$ as described previously and obtain

$$(t_0, r_0), (t_1, r_1), (t_2, r_2),...,(t_{n-1}, r_{n-1}), (t_n, r_n),$$

where $r_n=0,$ that is, the rate of change when there is no more counter values is set to zero.
Mathematically, the average rate of change forms a step function such that

$$r(t)=\begin{cases}
0, & t < t_{0} \\
r_i, & t_i \le t < t_{i+1}, \forall i\in\{0,...,n-1\} \\
0, & t \ge t_n
\end{cases},$$

where the rate of change is zero before we have observed any values, formally $t < t_{0}.$

We can recover the changes in counter values from the step function using an integral

$$\Delta v_{i}=\int_{t_{i}}^{t_{i+1}} r(t)\,dt = r_{i} \cdot (t_{i+1}-t_{i}) = r_{i}\cdot\Delta t_{i},\quad \forall i\in\{1,...,n-1\}.$$

We can transform a step function $r(t)$ into a step function $r^\prime(t)$ defined by 

$$(t_0^\prime, r_0^\prime), (t_1^\prime, r_1^\prime), (t_2^\prime, r_2^\prime),...,(t_{m-1}^\prime, r_{m-1}^\prime), (t_m^\prime, r_m^\prime),\quad m\in\mathbb{N}$$

where
$r_{j}^{\prime} = \Delta v_{j}^{\prime} / \Delta t_{j}^{\prime}$ and
$\Delta t_{j}^{\prime} = (t_{j+1}^\prime - t_{j}^\prime)$
such that it preserves the change in counter values in the new intervals

$$
\Delta v_{j}^\prime = 
\int_{t_{j}^\prime}^{t_{j+1}^\prime} r^\prime(t)\,dt = 
\int_{t_{j}^\prime}^{t_{j+1}^\prime} r(t)\,dt, \quad \forall j\in\{0,...,m-1\}.
$$

This transformation is useful if we have multiple step functions with steps as different timestamp and we need to convert the steps to happen at same timestamps.
In practice, we can avoid the transformation by querying the counters at same times and using them as timestamps.


## Computing density
> TODO: add plot of sum aggregate and heatmaps

> TODO: add another plot with different resolution

We can visualize an individual time series as step plot.
However, our configuration produces thousands of individual time series.
To visualize multiple time series, we must either compute an aggregate such as as sum or plot a heatmap of the distribution of values in each interval.

We define logarithmic binning function with *base* $b > 1$ as

$$f_{b}(x)=\lfloor \log_{b}(x) \rfloor.$$

We define an indicator function for counting values as follows

$$\mathbf{1}_{a}(x)=\begin{cases}
1, & x=a \\
0, & x\ne a
\end{cases}.$$

Let $R$ be a set of step functions such that steps occur at same times $t.$
Then, we can count many step values occur in the range $[b^k,b^{k-1})$ with base $b$ for bin $(t, k)$ as follows

$$z_{b}(t, k)=\sum_{r\in R} \mathbf{1}_{k}(f_b(r(t))).$$

The base parameter determines the *resolution* of the binning.


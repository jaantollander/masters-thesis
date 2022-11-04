\newpage

# Processing statistics
> TODO: add plot of raw counter values and computed rate of change, generate fake data

## Computing the rate of change
Let $t\in\mathbb{R}$ denote a *timestamp* and $v_{k}(t)\in\mathbb{R}$ such that $v_{k}(t)\ge 0$ denote a *counter value* of an operation at time $t$ for identifier $k\in K.$
Let the set of all possible identifiers be $K$ and the set of concrete identifiers at time $t$ be $K(t)\subseteq K$ consisting of tuples `(<target>, <job_id>)` for all entries for all targets.

If $k\in K(t),$ the counter value $v_{k}(t)$ is the value observed from the counter.
Otherwise, if $k\notin K(t),$ then the counter value is *implicitly zero*, that is, $v_k(t)=0.$
For example, the initial counter values are implicitly zero.

Sampling a counter value over time forms a time series.
Given two consequtive timestamps $t^{\prime}$ and $t$ where $t^\prime < t,$ we can calculate the *interval length* as 

$$\tau(t^{\prime}, t) = t - t^{\prime}.$$

Given an identifier $k\in K(t^{\prime})\cup K(t),$ if the new counter value $v_{k}(t)$ is greater than or equal to the previous value $v_{k}(t^{\prime})$, the previous value was incremented by $\Delta v$ during the interval, that is, $v_{k}(t)=v_{k}(t^{\prime})+\Delta v$
Otherwise, the counter value has reset and the previous counter value is implicitly zero, hence $v_{k}(t)=0+\Delta v.$
Combined, we can define the *counter increment* during the interval as

$$\Delta v_{k}(t^{\prime},t) = 
\begin{cases}
v_{k}(t) - v_{k}(t^{\prime}), & v_{k}(t) \ge v_{k}(t^{\prime}) \\
v_{k}(t), & v_{k}(t) < v_{k}(t^{\prime})
\end{cases}.$$

Then, we can calculate the *rate of change* during the interval as

$$r_k(t^{\prime},t)=\frac{\Delta v_{k}(t^{\prime},t)}{\tau(t^{\prime}, t)}.$$

Notewthat the rate of change is always positive given $t > t^{\prime},$ since we have $\tau(t^{\prime}, t) > 0$ and $\Delta v_{k}(t^{\prime}, t) > 0,$ which implies $r_k(t^{\prime}, t) > 0.$

To generalize, for any sampling $(t_1, t_2, ..., t_n)$ where $t_1 < t_2 < ... < t_n$ and $n\in\mathbb{N}$ and identifier $k\in K(t_1)\cup K(t_2)\cup ... \cup K(t_n)$ we can represent the rate of change as a step function

$$r_k(t)=\begin{cases}
r_k(t_1, t_2), & t_1 \le t < t_{2} \\
r_k(t_2, t_3), & t_2 \le t < t_{3} \\
\vdots \\
r_k(t_{n-1}, t_n), & t_{n-1} \le t < t_{n} \\
0 & \text{otherwise}
\end{cases}.$$

We can recover the counter increments from the step function using a definite integral

$$\Delta v_k(t_i, t_{i+1})=\int_{t_{i}}^{t_{i+1}} r_k(t)\,dt = r_k(t_i, t_{i+1}) \cdot \tau(t_{i}, t_{i+1}),\quad \forall i\in\{1,...,n-1\}.$$


## Transforming
We can transform a step function $r_k(t)$ into a step function $r_k^\prime(t)$ with timestamps $t_1^{\prime}, t_2^{\prime}, ..., t_m^{\prime}$ where $t_1^{\prime} < t_2^{\prime} < ... < t_m^{\prime}$ and $m\in\mathbb{N}$ such that it preserves the change in counter values in the new intervals by setting

$$\Delta v_k^{\prime}(t_i^{\prime}, t_{i+1}^{\prime})=\int_{t_{i}^{\prime}}^{t_{i+1}^{\prime}} r_k^{\prime}(t)\,dt = \int_{t_{i}^{\prime}}^{t_{i+1}^{\prime}} r_k(t)\,dt,\quad \forall i\in\{1,...,m-1\}.$$

This transformation is useful if we have multiple step functions with steps as different timestamp and we need to convert the steps to happen at same timestamps.
In practice, we can avoid the transformation by querying the counters at same times.


## Computing density over time
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


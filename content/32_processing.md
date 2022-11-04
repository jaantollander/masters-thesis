\newpage

# Processing statistics
> TODO: add plot of raw counter values and computed rate of change, generate fake data

## Computing the rate of change
Let $t\in\mathbb{R}$ denote a *timestamp* and $v_{k}(t)\in\mathbb{R}$ such that $v_{k}(t)\ge 0$ denote a *counter value* of an operation at time $t$ for identifier $k.$
The *set of identifiers* $K(t)$ at time $t$ consisting of tuples `(<target>, <job_id>)` for all entries for all targets.

- If $k\in K(t),$ the counter value is the *observed value* $v_{k}(t).$
- If $k\notin K(t),$ then the counter value is *implicitly zero*, that is, $v_k(t)=0.$

For conciseness, we denote $v$ without the subscript as counter value for unspecified $k$ when it is not important which identifier is in question.

Sampling a counter value over time forms a time series.
Given two consequtive timestamps $t^{\prime}$ and $t$ where $t^\prime < t,$ we can calculate the *interval length* as 

$$\tau(t^{\prime}, t) = t - t^{\prime}.$$

If the new counter value $v_{k}(t)$ is greater than or equal to the previous value $v_{k}(t^{\prime})$, the previous value was incremented by $\Delta v$ during the interval, that is, $v_{k}(t)=v_{k}(t^{\prime})+\Delta v$
Otherwise, the counter value has reset and the previous counter value is implicitly zero, hence $v_{k}(t)=0+\Delta v.$
Combined, we can define the *counter increment* during the interval as

$$\Delta v_{k}(t^{\prime},t) = 
\begin{cases}
v_{k}(t) - v_{k}(t^{\prime}), & v_{k}(t) \ge v_{k}(t^{\prime}) \\
v_{k}(t), & v_{k}(t) < v_{k}(t^{\prime})
\end{cases}.$$


Then, we can calculate the *rate of change* during the interval as

$$r(t^{\prime},t)=\frac{\Delta v_{k}(t^{\prime},t)}{\tau(t^{\prime}, t)}.$$

Note that the rate of change is always positive given $t > t^{\prime},$ since we have $\tau(t^{\prime}, t) > 0$ and $\Delta v_{k}(t^{\prime}, t) > 0,$ which implies $r(t^{\prime}, t) > 0.$


## Boundaries
If a particular `job_id` has not yet performed any operations, its counters contain implicit zeros, that is, they not in the output of the statistics.
In these cases, we can infer the *initial counter* $(t_0, v_0)$ where $v_0=0$ and set $t_0$ to the timestmap of last recording interval.
For the first recording interval, we cannot infer $t_0$ and we need to discard the initial counter.
The *observed counters* are $(t_1,v_1),...,(t_n,v_n),$ where $n\in\mathbb{N}.$
Then, given a series of counter values

$$(t_0, v_0), (t_1, v_1), (t_2, v_2), ..., (t_{n-1}, v_{n-1}), (t_n, v_n),$$

we can compute the series of rates of change $r_i$ in the interval $[t_i,t_{i+1})$ as described previously and obtain

$$(t_0, r_0), (t_1, r_1), (t_2, r_2),...,(t_{n-1}, r_{n-1}), (t_n, r_n),$$

where $r_n=0,$ that is, the rate of change when there is no more counter values is set to zero.
Mathematically, the rate of change forms a step function such that

$$r(t)=\begin{cases}
0, & t < t_{0} \\
r_i, & t_i \le t < t_{i+1}, \forall i\in\{0,...,n-1\} \\
0, & t \ge t_n
\end{cases},$$

where the rate of change is zero before we have observed any values, formally $t < t_{0}.$

We can recover the changes in counter values from the step function using an integral

$$\Delta v_{i}=\int_{t_{i}}^{t_{i+1}} r(t)\,dt = r_{i} \cdot (t_{i+1}-t_{i}) = r_{i}\cdot\Delta t_{i},\quad \forall i\in\{1,...,n-1\}.$$


## Transforming
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


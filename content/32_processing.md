\newpage

# Processing statistics
> TODO: add plot of raw counter values and computed rate of change, generate fake data

## Rate of change
Let $t\in\mathbb{R}$ denote a *timestamp* and $c_{k}(t)\in\mathbb{R}$ such that $c_{k}(t)\ge 0$ denote a *concrete counter value* of an operation at time $t$ for identifier $k\in K.$
Let the set of all possible identifiers be $K$ and the set of concrete identifiers at time $t$ be $K(t)\subseteq K$ consisting of tuples `(<target>, <job_id>)` for all entries for all targets.

We denote *counter value* as $v_k(t).$
If $k\in K(t),$ the counter value $c_{k}(t)$ is the value observed from the counter.
Otherwise, if $k\notin K(t),$ then the counter value is *implicitly zero*.
For example, the initial counter values are implicitly zero.

$$v_{k}(t)=
\begin{cases}
c_k(t), & k\in K(t) \\
0, & k\notin K(t) \\
\end{cases}.$$

Sampling a counter value over time forms a time series.
Given two consequtive timestamps $t^{\prime}$ and $t$ where $t^\prime < t,$ we can calculate the *interval length* as 

$$\tau(t^{\prime}, t) = t - t^{\prime}.$$

Given an identifier $k\in K(t^{\prime})\cup K(t),$ if the new counter value $v_{k}(t)$ is greater than or equal to the previous value $v_{k}(t^{\prime})$, the previous value was incremented by $\delta_{k}(t^{\prime},t)$ during the interval, that is, $v_{k}(t)=v_{k}(t^{\prime})+\delta_{k}(t^{\prime},t)$
Otherwise, the counter value has reset and the previous counter value is implicitly zero, hence $v_{k}(t)=0+\delta_{k}(t^{\prime},t).$
Combined, we can define the *counter increment* during the interval as

$$\delta_{k}(t^{\prime},t) = 
\begin{cases}
v_{k}(t) - v_{k}(t^{\prime}), & v_{k}(t) \ge v_{k}(t^{\prime}) \\
v_{k}(t), & v_{k}(t) < v_{k}(t^{\prime})
\end{cases}.$$

Then, we can calculate the *rate of change* during the interval as

$$r_k(t^{\prime},t)=\frac{\delta_{k}(t^{\prime},t)}{\tau(t^{\prime}, t)}.$$

Notewthat the rate of change is always positive given $t > t^{\prime},$ since we have $\tau(t^{\prime}, t) > 0$ and $\delta_{k}(t^{\prime}, t) \ge 0,$ which implies $r_k(t^{\prime}, t) \ge 0.$

To generalize, for any sampling $(t_1, t_2, ..., t_n)$ where $t_1 < t_2 < ... < t_n$ and $n\in\mathbb{N}$ and identifier $k\in K(t_1)\cup K(t_2)\cup ... \cup K(t_n)$ we can represent the rate of change as a step function

$$r_k(t)=\begin{cases}
r_k(t_1, t_2), & t_1 < t \le t_{2} \\
r_k(t_2, t_3), & t_2 < t \le t_{3} \\
\vdots \\
r_k(t_{n-1}, t_n), & t_{n-1} < t \le t_{n} \\
0 & \text{otherwise}
\end{cases}.$$

We can recover the counter increments from the step function using a definite integral

$$
\delta_k(t_{i-1}, t_{i})
=
\int_{t_{i-1}}^{t_{i}} r_k(t)\,dt
=
r_k(t_{i-1}, t_{i}) \cdot \tau(t_{i-1}, t_{i}),\quad \forall i\in\{2,...,n\}.
$$


## Transforming
We can transform a step function $r_k(t)$ into a step function $r_{k}^\prime(t)$ with timestamps $t_1^{\prime}, t_2^{\prime}, ..., t_m^{\prime}$ where $t_1^{\prime} < t_2^{\prime} < ... < t_m^{\prime}$ and $m\in\mathbb{N}$ such that it preserves the change in counter values in the new intervals by setting

$$
\delta_k^{\prime}(t_{i-1}^{\prime}, t_{i}^{\prime})
=
\int_{t_{i-1}^{\prime}}^{t_{i}^{\prime}} r_k^{\prime}(t)\,dt
=
\int_{t_{i-1}^{\prime}}^{t_{i}^{\prime}} r_k(t)\,dt,\quad \forall i\in\{2,...,m\}.$$

This transformation is useful if we have multiple step functions with steps as different timestamp and we need to convert the steps to happen at same timestamps.
In practice, we can avoid the transformation by querying the counters at same times.


## Summation
Sum $r_{K^\prime}(t)$ over identifiers $K^{\prime}\subseteq K$ is defined as

$$r_{K^{\prime}}(t) = \sum_{k\in K^{\prime}} r_{k}(t).$$


## Density over time
We define a function which indicates if the logarithmic value of $x\in\mathbb{R}$ with *base* $b\in \mathbb{N}$ where $b > 1$ belongs to the *bin* $y\in \mathbb{Z}$ as

$$\mathbf{1}_{b}(x, y)=\begin{cases}
1, & (x > 0) \wedge (\lfloor \log_{b}(x) \rfloor = y) \\
0, & \text{otherwise} \\
\end{cases}.$$

Let $R$ be a set of step functions.

$$z_{b}(t, y)=\sum_{r_k\in R} \mathbf{1}_{b}(r_k(t), y).$$

Then, we can count many step values occur in the range $[b^k,b^{k-1})$ with base $b$ for bin $(t, a)$ as follows

The base parameter determines the *resolution* of the binning.


## Practical Usage
TODO

We can visualize an individual time series as step plot.
However, our configuration produces thousands of individual time series.
To visualize multiple time series, we must either compute an aggregate such as as sum or plot a heatmap of the distribution of values in each interval.


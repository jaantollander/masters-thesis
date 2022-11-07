\newpage

# Processing statistics
## Rate of change over an interval
Let $K$ denote the set of *all possible identifiers* and $t\in\mathbb{R}$ denote a *timestamp*.
Then, we define $K(t)\subseteq K$ as the set of *concrete identifiers* at time $t$ and $c_{k}(t)\in\mathbb{R}$ such that $c_{k}(t)\ge 0$ as the *concrete counter value* at time $t$ for concrete identifier $k\in K(t).$

We denote *counter value* as $v_k(t)$ for an arbitraty identifier $k\in K$ at time $t.$
Its value is the concrete counter value if the identifier $k$ is concrete and zero value if the identifier is not concrete.
Formally, we have

\begin{equation}
v_{k}(t)=
\begin{cases}
c_k(t), & k\in K(t) \\
0, & k\notin K(t) \\
\end{cases}.
\label{eq:counter-value}
\end{equation}

We can sample the counter value over time as a streaming time series.
Given previous timestamp $t^{\prime}$ and current timestamp $t$ in the stream such that $t^\prime < t,$ we can calculate an *interval length* as 

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

Note that the rate of change is always non-negative given $t > t^{\prime},$ since we have $\tau(t^{\prime}, t) > 0$ and $\delta_{k}(t^{\prime}, t) \ge 0,$ which implies $r_k(t^{\prime}, t) \ge 0.$


## Rate of change over time
Generally, we can represent the rate of change as a step function over continuous time $t$ given a sampling $(t_1, t_2, ..., t_n)$ where $t_1 < t_2 < ... < t_n$ and $n\in\mathbb{N}$ with identifier $k\in K(t_1)\cup K(t_2)\cup ... \cup K(t_n)$ as

$$r_k(t)=\begin{cases}
r_k(t_{i-1}, t_{i}), & t_{i-1} < t \le t_{i},\quad \forall i\in\{2,...,n\} \\
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

Sum $r_{K^\prime}(t)$ over identifiers $K^{\prime}\subseteq K$ is defined as

$$r_{K^{\prime}}(t) = \sum_{k\in K^{\prime}} r_{k}(t).$$


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


## Density over time
We define a function which indicates if the logarithmic value of $x\in\mathbb{R}$ with *base* $b\in \mathbb{N}$ where $b > 1$ belongs to the *bucket* $y\in \mathbb{Z}$ as

$$\mathbf{1}_{b}(x, y)=\begin{cases}
1, & b^y \le x < b^{y+1} \\
0, & \text{otherwise} \\
\end{cases}.$$

Let $R$ be a set of step functions.
Then, we define the density over time as a counting function

$$z_{b}(t, y)=\sum_{r_k\in R} \mathbf{1}_{b}(r_k(t), y).$$

The base parameter determines the *resolution* of the bucketing.

In pratice, we can use the logarithmic floor function to compute the bucket $y$ of a value $x,$ because of the relationship 

$$(x > 0) \wedge (\lfloor \log_{b}(x) \rfloor = y)
\quad\equiv\quad
b^y \le x < b^{y+1}.$$


## Practical Usage
TODO

$K(t)$ consisting of tuples `(<target>, <job_id>)` for all entries for all targets.

We can visualize an individual time series as step plot.
However, our configuration produces thousands of individual time series.
To visualize multiple time series, we must either compute an aggregate such as as sum or plot a heatmap of the distribution of values in each interval.


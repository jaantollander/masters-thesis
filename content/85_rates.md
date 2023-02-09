\clearpage

# Computing and aggregating rates
We compute rates from counter values.
A rate tells us how much the value changes on average during an interval.
We referer to the values obtained from Jobstast as *observed values* in contrast to implicit zero values of counters outside the observation intervals, such as the initial counter.
The observation time is called a *timestamp*.
We identify each time series of counter values by a unique *identifier*.
We refer to the identifiers of the observed counters as *observed identifiers*.
The size of the set of observed identifiers tells us how many individual time series Jobstats is tracking at a given time.
It is proportional to how much data we accumulate at each observation.
We regard the observed identifiers as a subset of *all identifiers*, which is the set of all possible identifiers, depending on the chosen identifier scheme.


## Computing rates from counters
Let $\mathcal{K}$ denote the set of *all identifiers* and $t\in\mathbb{R}$ denote a *timestamp*.
Then, we define $K(t)\subseteq \mathcal{K}$ as the set of *observed identifiers* at time $t$ and $c_{k}(t)\in\mathbb{R}$ such that $c_{k}(t)\ge 0$ as the *observed counter value* at time $t$ for observed identifier $k\in K(t).$

We denote *counter value* as $v_k(t)$ for an arbitraty identifier $k\in \mathcal{K}$ at time $t.$
Its value is the observed counter value if we observe the identifier $k$ and zero if we do not.
Formally, we have

\begin{equation}
v_{k}(t)=
\begin{cases}
c_k(t), & \text{if } k\in K(t) \\
0, & \text{if } k\notin K(t) \\
\end{cases}.
\label{eq:counter-value}
\end{equation}

We can sample the counter value over time as a streaming time series.
Given previous timestamp $t^{\prime}$ and current timestamp $t$ in the stream such that $t^\prime < t,$ we can calculate the *observation interval* as 

\begin{equation}
\tau(t^{\prime}, t) = t - t^{\prime}.
\label{eq:observation-interval}
\end{equation}

Given an identifier $k\in K(t^{\prime})\cup K(t),$ if the new counter value $v_{k}(t)$ is greater than or equal to the previous value $v_{k}(t^{\prime})$, the previous value was incremented by $\delta_{k}(t^{\prime},t)$ during the interval, that is, $v_{k}(t)=v_{k}(t^{\prime})+\delta_{k}(t^{\prime},t).$
Otherwise, the counter value has reset, and the previous counter value is implicitly zero, hence $v_{k}(t)=0+\delta_{k}(t^{\prime},t).$
Combined, we can define the *counter increment* during the interval as

\begin{equation}
\delta_{k}(t^{\prime},t) = 
\begin{cases}
v_{k}(t) - v_{k}(t^{\prime}), & \text{if } v_{k}(t) \ge v_{k}(t^{\prime}) \\
v_{k}(t), & \text{if } v_{k}(t) < v_{k}(t^{\prime})
\end{cases}.
\label{eq:counter-increment}
\end{equation}

Then, we can calculate the *rate of change* during the interval as

\begin{equation}
r_k(t^{\prime},t)=\frac{\delta_{k}(t^{\prime},t)}{\tau(t^{\prime}, t)}.
\label{eq:rate}
\end{equation}

Note that the rate of change is always non-negative given $t > t^{\prime},$ since we have $\tau(t^{\prime}, t) > 0$ and $\delta_{k}(t^{\prime}, t) \ge 0,$ which implies $r_k(t^{\prime}, t) \ge 0.$

Generally, we can represent the rate of change as a step function over continuous time $t$ with identifier $k\in K$ given a sampling $(t_1, t_2, ..., t_n)$ where $t_1 < t_2 < ... < t_n$ and $n\in\mathbb{N}$ and $K = K(t_1)\cup K(t_2)\cup ... \cup K(t_n)$ as

\begin{equation}
r_k(t)=\begin{cases}
r_k(t_{i-1}, t_{i}), & \text{if } t_{i-1} < t \le t_{i},\quad \forall i\in\{2,...,n\} \\
0 & \text{otherwise}
\end{cases}.
\label{eq:rate-general}
\end{equation}

We can recover the counter increments from the step function using a definite integral

\begin{equation}
\delta_k(t_{i-1}, t_{i})
=
\int_{t_{i-1}}^{t_{i}} r_k(t)\,dt
=
r_k(t_{i-1}, t_{i}) \cdot \tau(t_{i-1}, t_{i}),\quad \forall i\in\{2,...,n\}.
\label{eq:rate-integral}
\end{equation}


![
The upper graph shows a sampling of a counter values $v_{k}(t)$ from Equation \eqref{eq:counter-value} with timestamps $t_{1},t_{2},...,t_{9}.$
The lower graph shows the computed rate $r_{k}(t)$ as described in Equation \eqref{eq:rate-general}.
The graphs also show the observation interval $\tau(t_4,t_5)$ from Equation \eqref{eq:observation-interval}, counter increment $\delta_{k}(t_4,t_5)$ from Equation \eqref{eq:counter-increment}, and individual rate $r_{k}(t_4,t_5)$ from Equation \eqref{eq:rate}
The red box demonstrates the relationship $\delta_k(t_4,t_5)=r_k(t_4,t_5)\cdot\tau(t_4,t_5),$ which recovers the counter increment with a definitive integral, seen in Equation \eqref{eq:rate-integral}.
\label{fig:counter-rate}
](figures/counter-rate.svg)


## Transforming timestamps
Using the property \eqref{eq:rate-integral}, we can transform a step function $r_k(t)$ into a step function $r_{k}^\prime(t)$ with timestamps $t_1^{\prime}, t_2^{\prime}, ..., t_m^{\prime}$ where $t_1^{\prime} < t_2^{\prime} < ... < t_m^{\prime}$ and $m\in\mathbb{N}$ such that it preserves the change in counter values in the new intervals by first setting as

\begin{equation}
\delta_k^{\prime}(t_{i-1}^{\prime}, t_{i}^{\prime})
=
\int_{t_{i-1}^{\prime}}^{t_{i}^{\prime}} r_k^{\prime}(t)\,dt
=
\int_{t_{i-1}^{\prime}}^{t_{i}^{\prime}} r_k(t)\,dt,\quad \forall i\in\{2,...,m\}.
\label{eq:counter-increment-new}
\end{equation}

Then, by computing the rate of change using \eqref{eq:rate}.
This transformation is helpful if we have multiple step functions with steps as different timestamps, and we need to convert the steps to happen at identical timestamps.
In practice, we can avoid the transformation by querying the counters simultaneously.


\clearpage

## Summation
We define the sum of rates of change over identifiers $K \subseteq \mathcal{K}$ as

\begin{equation}
r_{K}(t) = \sum_{k\in K} r_{k}(t).
\label{eq:rate-sum}
\end{equation}

If all step function $r_k$ where $k\in K$ have the steps at the identical timestamp, the summation is easy.
We sum all the values at each timestamp.
Otherwise, we have to resort to a more complex algorithm whose description is out of the scope of this thesis.
In practice, we transform the timestamps of all rates to identical timestamps using \eqref{eq:counter-increment-new} before summation if necessary.


## Density
We define a function that indicates if the logarithmic value of $x\in\mathbb{R}$ with *base* $b\in \mathbb{N}$ where $b > 1$ belongs to the *bucket* $y\in \mathbb{Z}$ as

\begin{equation}
\mathbf{1}_{b,y}(x)=\begin{cases}
1, & \text{if } b^y \le x < b^{y+1} \\
0, & \text{otherwise} \\
\end{cases}.
\label{eq:indicator-function}
\end{equation}

Let $R$ be a set of step functions.
Then, we define the density over time as a counting function as

\begin{equation}
z_{b,y}(t)=\sum_{r_k\in R} \mathbf{1}_{b,y}(r_k(t)).
\label{eq1:counting-function}
\end{equation}

The base parameter determines the *resolution* of the bucketing.

In practice, we can use the logarithmic floor function to compute the bucket $y$ of a value $x>0,$ because the relationship $\lfloor \log_{b}(x) \rfloor = y$ is logically equivalent to $b^y \le x < b^{y+1}.$


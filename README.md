# Master's Thesis
- Title: Monitoring parallel file system usage in a high-performance computer cluster
- Author: Jaan Tollander de Balsch
- Supervisor: Prof. Petteri Kaski
- Advisor: Dr. Sami Ilvonen
- Degreeprogram: Computer, Communication and Information Sciences
- Major: Computer Science
- Keywords: monitoring computer systems, observability, computer cluster, high-performance computing, parallel file system, Lustre, I/O behavior, time series analysis, exploratory data analysis
- [License](./LICENSE): This work is licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0) license.

[**Download the thesis (PDF)**](https://github.com/jaantollander/masters-thesis/blob/build/sci_2023_tollander-de-balsch_jaan.pdf)


## Abstract
Many high-performance computer clusters, rely on a system-wide, shared, parallel file system for large storage capacity and bandwidth.
A shared file system is available across the entire system, making it user-friendly but prone to problems from heavy use.
Such use can cause congestion and slow down or even halt the whole system, harming all users who use the parallel file system.
In this thesis, we investigate whether monitoring file system usage in a production system at CSC can help identify the causes of slowdowns, such as specific users or jobs.
The long-goal at CSC is to build an automatic, real-time monitoring and warning system that system administrators can use to make decisions on alleviating the slowdowns.
Specifically, we monitor the usage of the Lustre parallel file system with Lustre Jobstats feature in the Puhti cluster, which is a petascale cluster with a diverse user base.
We explain the necessary details of the Puhti cluster and our monitoring system to understand the Lustre file system usage data.
During the thesis, we discovered issues in the data quality from Lustre Jobstats.
The issues affected identifiers in the data, making some data unreliable and limiting our ability to build an automatic, real-time analysis.
Nevertheless, we obtained a feasible data set for explorative data analysis.
We demonstrate 24 hours of monitoring data by visually demonstrating file system usage patterns at low and high-level.
Furthermore, we show that we can use file system usage data to identify causes of relative changes in I/O trends, particularly large relative increases.
Finally, we explore ideas for future work on monitoring file system usage with reliable data from longer periods.


## Usage
The `thesis` shell script convert the Markdown content to PDF via LaTeX.
It depends on the `pandoc`, `texlive`, `texlive-latex-extra`, `texlive-lang-european` and `rsvg-convert`.
We can build the various documents format using the `thesis` script with the following arguments.

```bash
./thesis pdf
```

We can use the preview for automatically running a build command if files in `metadata` or `content` files change.
It depends on `inotify-tools`.

```bash
./thesis preview pdf
```

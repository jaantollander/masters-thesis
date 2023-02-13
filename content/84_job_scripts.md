\clearpage

# Slurm job scripts
In Puhti, we can submit a job to the Slurm scheduler as a shell script via the `sbatch` command.
We can specify the options as command line arguments as we invoke the command or in the script as comments.
The script specifies job steps using the `srun` command.
Next, we show three job script examples for different job sizes

```sh
#!/usr/bin/env bash
#SBATCH --job-name=<job-name>
#SBATCH --account=<project>
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
srun <program>
```

The above script is an example of a small, sequential batch job with a single job step, that is, `srun` command.


```sh
#!/usr/bin/env bash
#SBATCH --job-name=<job-name>
#SBATCH --account=<project>
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --array=1-100
srun <program> $SLURM_ARRAY_TASK_ID
```

It is also common to run multiple similar sequential batch jobs independent from one another with slight variations, for example, in initial conditions.
We can achieve that by turning it into an array job by adding the `array` argument with the desired range and accessing the array ID via an environment variable.


```sh
#!/usr/bin/env bash
#SBATCH --job-name=<job-name>
#SBATCH --account=<project>
#SBATCH --partition=large
#SBATCH --time=02:00:00
#SBATCH --nodes=2
#SBATCH --tasks-per-node=2
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=2G
#SBATCH --gres=nvme:100
# 1. job step
srun --nodes 2 --ntasks 1 <program-1>
# 2. job step
srun <program-2>
# 3. job step
srun --nodes 1 --ntasks 2 <program-3> &
# 4. job step
srun --nodes 1 --ntasks 2 <program-4> &
# Wait for jobs 2. and 3. to complete
wait
```

Finally, the we can run large parallel batch jobs.
The above script is an example of a large parallel batch job with four job steps.
For example, it could perform the following steps.
The first program runs on the first job step and could load data to the local disk.
The second program runs on the second job step utilizing all given nodes, tasks, and CPUs and the majority of the given time.
It is a large parallel program, such as a large, well-parallelizing simulation communicating via MPI.
The third and fourth programs' job steps run parallel after the first step, utilizing all tasks and CPUs from a single node.
These programs could be post-processing steps, for example, processing and backing up the simulation results.


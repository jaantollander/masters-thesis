\clearpage

# Slurm job scripts
We can submit a job to the Slurm scheduler as a shell script via the `sbatch` command.
We can specify the options as command line arguments as we invoke the command or in the script as comments.
The script specifies job steps using the `srun` command.


## Small sequential job
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

The above script is an example of a small, sequential batch job with a single job step (`srun` command).


## Multiple similar sequential jobs
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

It is also common to run multiple such jobs independent of each other with slight variation for example in initial conditions.
We can achieve that by turning it into an array job by adding the `array` argument with desired range and accessing the array ID via an environment variable.


## Large parallel job
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
# Wait for job 2. and 3. to complete
wait
```

The above script is an example of a large parallel batch job with four job steps.
For example,
The first program will run on the first job step and could load data to the local disk.
The second program will run on the second job step utilizing all given nodes, tasks, and cpus and the majority of the given time.
It would be is a large parallel program such as a large, well parallelizing simulation communicating via MPI.
The third and fourth programs job steps will run in parallel after the first step, both utilizing all tasks and CPUs from a single node.
These programs could be programs for post processing steps, for example, processing and backing up the simulation results.


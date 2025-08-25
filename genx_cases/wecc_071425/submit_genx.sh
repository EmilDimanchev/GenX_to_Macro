#!/bin/bash

#SBATCH --job-name=utes_pjm        # create a short name for your job
#SBATCH --output=slurm-%A.out # stdout file
#SBATCH --error=slurm-%A.err  # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=4        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=64GB         # memory per cpu-core (4G is default)
#SBATCH --constraint="amd"
#SBATCH --time=12:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=fail          # send email when job ends
#SBATCH --mail-type=end          # send email when job ends
#SBATCH --mail-user=ql7299@princeton.edu

module load gurobi/10.0.1 
module load julia/1.9.1

julia --project='/home/ql7299/GenX_utes' "Run.jl"

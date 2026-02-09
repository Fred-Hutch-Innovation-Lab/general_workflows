#!/bin/bash

# Job Options- must be before *any* executable lines

#SBATCH --job-name="mixcr_cellecta"
#SBATCH --output=mixcr.out
#SBATCH --error=mixcr.err
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=32        # cpu-cores per task (>1 if multi-threaded tasks) ## Gizmo nodes have 36 cores
#SBATCH --mem-per-cpu=10G        # memory per cpu-core
#SBATCH --time=72:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=begin        # send email when job begins
#SBATCH --mail-type=end          # send email when job ends
#SBATCH --mail-type=fail         # send email if job fails
#SBATCH --mail-user=dgratz@fredhutch.org

module load Apptainer

# R1 = 1, R2 = 2
# 3 = sample name
# 4 = outdir
# 5 tagpattern

apptainer exec \
    --bind ./mixcr_license.txt:/opt/mixcr/mi.license:ro,/loc/scratch/,/fh/fast/newell_e/dgratz/cellecta_august_2025,./mixcr_loop.sh:/mixcr_loop.sh \
    mixcr_4.6.0-226-devel.sif \
    /mixcr_loop.sh /fh/fast/newell_e/dgratz/cellecta_august_2025

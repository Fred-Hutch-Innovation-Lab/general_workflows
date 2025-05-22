#!/bin/bash
SLURM_OPTS="--job-name=cellranger \
             --output=sbatch.out \
             --error=sbatch.err \
             --nodes=1 \
             --ntasks=1 \
             --cpus-per-task=8 \
             --mem-per-cpu=8G \
             --time=10:00:00 \
             --mail-type=begin \
             --mail-type=end \
             --mail-type=fail \
             --mail-user=dgratz@fredhutch.org"

# Check for the correct number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <sample_name> <config_csv_path>" 
    exit 1
fi
sample=$1
config_csv=$2

# Validate that the config file exists
if [ ! -f "$config_csv" ]; then
    echo "Error: Config CSV file not found at $config_csv"
    exit 1
fi

module load CellRanger
sbatch $SLURM_OPTS \
    --wrap "cellranger multi --id=$sample --csv=$config_csv"
  

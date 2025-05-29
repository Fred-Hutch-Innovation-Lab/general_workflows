#!/bin/bash

## Requires these modules:
# module load seqtk/1.3-GCC-10.2.0
# module load pigz/2.8-GCCcore-13.2.0

if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <file_location> <file_pattern> <integer> <output_directory> <string_list> <threads>"
    echo "Example: $0 /path/to/files '*.txt' 5000 /path/to/output_dir 'R1,R2' 4"
    exit 1
fi

file_location="$1"
file_pattern="$2"
target_reads="$3"
output_directory="$4"
filetypes="$5"
threads="$6"

if [ ! -d $file_location ]; then
    echo "Error: File not found at '$file_location'."
    exit 1
fi

if ! [[ $target_reads =~ ^[0-9]+$ ]]; then
    echo "Error: '$target_reads' is not a valid integer."
    exit 1
fi

if ! [[ $threads =~ ^[0-9]+$ ]]; then
    echo "Error: '$threads' is not a valid integer."
    exit 1
fi

if [ ! -d $output_directory ]; then
    echo "Error: Directory not found at '$output_directory'. Creating it..."
    mkdir -p $output_directory || {
        echo "Error: Failed to create directory at '$output_directory'."
        exit 1
    }
fi

IFS=',' read -r -a filetypes <<< "$filetypes"

for filetype in "${filetypes[@]}"; do
    file=($file_location/$file_pattern*$filetype*fastq*);
    seqtk sample -s100 ${file[0]} $target_reads | pigz > $output_directory/${file_pattern}_downsampled_${target_reads}_${filetype}.fastq.gz
done



# fastq_dir="/fh/fast/_IRC/FHIL/grp/BM02_FluentV4_2024/fastqs/full"
# outdir="/fh/fast/_IRC/FHIL/grp/BM02_FluentV4_2024/fastqs/downsampled"

# declare -A target_reads

# # target_reads["F1A"]=449738139 # Downsampling not needed
# # target_reads["F1B"]=415600000
# target_reads["F5A"]=419575000
# # target_reads["F5B"]=380850000

# # for sample in "${!target_reads[@]}"; do
# #     # echo $sample ${target_reads[$sample]};
# #     for filetype in R1 R2; do
#         seqtk sample -s100 ${fastq_dir}/*${sample}*${filetype}*.fastq.gz ${target_reads[$sample]} | pigz > ${outdir}/B2-FBv4_${sample}_downsampled_${filetype}.fastq.gz
#     # done
# # done


# Job Options- must be before *any* executable lines

#SBATCH --job-name="downsample"
#SBATCH --output=sbatch.out
#SBATCH --error=sbatch.err
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=36       # cpu-cores per task (>1 if multi-threaded tasks) ## Gizmo nodes have 36 cores
#SBATCH --mem-per-cpu=8G        # memory per cpu-core
#SBATCH --time=12:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=begin        # send email when job begins
#SBATCH --mail-type=end          # send email when job ends
#SBATCH --mail-type=fail         # send email if job fails
#SBATCH --mail-user=dgratz@fredhutch.org

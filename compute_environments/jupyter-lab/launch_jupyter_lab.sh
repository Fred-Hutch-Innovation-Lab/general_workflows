#!/bin/sh
#SBATCH --job-name=jupyter-lab
#SBATCH --time=5-00:00:00   # days-hours:minutes:seconds
#SBATCH --ntasks=1          
#SBATCH --cpus-per-task=8   # per sciwiki, use CPUs to inform mem. 1 CPU = 4 Gb
#SBATCH --mem-per-cpu=4G
#SBATCH --output=jupyter-lab.job.out
#SBATCH --error=jupyter-lab.job.err

module load Apptainer

# Select a more secure password if desired
export APPTAINERENV_JUPYTER_PASSWORD="" # $(openssl rand -base64 15)
export IMAGE_NAME="jupyter.sif"

export FILE_BASE="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/general_workflows/compute_environments/jupyter-lab"
# Found in $FILE_BASE/images/

export USER_FILE_BASE="${FILE_BASE}/user/${USER}"
workdir=$(mktemp -d)
export APPTAINERENV_USER=$(id -un)

# export APPTAINER_BIND="${workdir}/jupyter_lab_config.py:/etc/jupyter/jupyter_lab_config.py"

# Get an available port
export PORT=$(fhfreeport)

cat 2>&1 <<END
Jupyter Lab is starting up...

Connection Information:
- URL: http://$(hostname).fhcrc.org:${PORT}
- Password: ${APPTAINERENV_JUPYTER_PASSWORD}

Once the server is running, you can access it directly from your browser at the URL above.
Make sure you're connected to the VPN if accessing from outside the network.

When done using Jupyter Lab, terminate the job by:

1. Close all Jupyter notebooks and stop the kernel
2. Issue the following command on the login node:

      scancel -f ${SLURM_JOB_ID}
END

# Launch Jupyter Lab with Apptainer
singularity exec --cleanenv \
                 --scratch /run,/tmp \
                 --workdir $(mktemp -d) \
                 --bind /home:/home \
                 --bind /fh:/fh \
                 ${FILE_BASE}/images/${IMAGE_NAME} \
   jupyter lab --config=${USER_FILE_BASE}/jupyter_lab_config.py \
               --port=${PORT} \
               --ip=0.0.0.0 \
               --no-browser \
               --allow-root \
               --NotebookApp.token='' \
               --NotebookApp.password=${APPTAINERENV_JUPYTER_PASSWORD}

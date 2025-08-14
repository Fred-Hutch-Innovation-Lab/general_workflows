# Jupyter Lab on FHIL HPC

This directory contains scripts and configuration for running Jupyter Lab instances on the FHIL HPC cluster using Apptainer containers.

## Prerequisites

1. **Apptainer Image**: You need a Jupyter Lab Apptainer image (`.sif` file) placed in the `images/` directory
2. **Directory Structure**: Ensure the following directory structure exists:
   ```
   compute_environments/jupyter-lab/
   ├── images/
   │   └── jupyter_lab.sif
   └── user/
       └── $USER/
           └── jupyter_config/
   ```
3. **Package Management**: The image uses minimal packages and is intended more for tracking system dependencies. Python packages are managed with `uv` or `poetry`, R packages with `renv`.

## Usage

### 1. Submit the SLURM Job

```bash
sbatch launch_jupyter_lab.sh
```

### 2. Monitor the Job

Check the job status and output:
```bash
squeue -u $USER
tail -f /home/$USER/jupyter-lab.job.$SLURM_JOB_ID.out
```

### 3. Access Jupyter Lab

Once the job is running, you'll see connection information in the stdout:
- URL: `http://<hostname>.fhcrc.org:<port>`
- Token: The generated token (if using token authentication)

### 4. Terminate the Job

When you're done:
1. Close all Jupyter notebooks and stop kernels
2. Cancel the SLURM job:
   ```bash
   scancel -f $SLURM_JOB_ID
   ```

## Configuration

The script automatically:
- Allocates 8 CPUs and 32GB RAM (configurable in SLURM directives)
- Sets a 5-day time limit
- Creates a temporary working directory
- Generates a random port using `fhfreeport`
- Mounts necessary directories (`/home`, `/fh`)
- Configures Jupyter Lab for remote access

## Customization

### Resource Allocation
Modify the SLURM directives at the top of `launch_jupyter_lab.sh`:
```bash
#SBATCH --cpus-per-task=4    # Increase CPU cores
#SBATCH --mem-per-cpu=8G     # Increase memory per CPU
#SBATCH --time=7-00:00:00    # Increase time limit
```

### Package Management

The image is designed to be minimal and lightweight. Package management is handled at runtime:

#### Python Packages
- Use `uv` or `poetry` for fast Python package management:
  ```bash
  uv add pandas numpy matplotlib
  uv run python -c "import pandas; print('pandas installed')"
  ```

#### R Packages
- Use `renv` for reproducible R environments:
  ```r
  install.packages("renv")
  renv::init()
  renv::install(c("tidyverse", "ggplot2"))
  ```

#### System Libraries
- Edit `build_image.def` and uncomment needed system libraries
- Rebuild the image when system dependencies change

### Image Path
Update `FILE_BASE` and `IMAGE_NAME` variables to point to your specific Jupyter Lab image.

## Security Notes

- The current configuration disables token authentication for simplicity
- Consider enabling token-based authentication for production use
- Ensure proper network access controls are in place
- The script binds mount directories - review security implications

## Dependencies

- SLURM job scheduler
- Apptainer/Singularity
- `fhfreeport` utility (FHIL-specific)
- Jupyter Lab Apptainer image

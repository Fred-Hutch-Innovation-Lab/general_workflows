
# Customize an image

You can directly [edit the Apptainer `.def`](https://apptainer.org/docs/user/1.0/build_a_container.html#building-containers-from-apptainer-definition-files) file to add dependencies.  Once the definition file is updated, build the `.sif`. Try to use semantic versioning to record versions.

```{shell}
apptainer build <>.X.Y.Z.sif <>.def
```

## Converting dockerfile to def

If Apptainer definition file syntax is scary, you can write a dockerfile and convert it with [Singularity python](https://singularityhub.github.io/singularity-cli/recipes).

```{shell}
ml fhPython
spython recipe ./rstudio_FHIL.4.4.3.dockerfile > rstudio_FHIL.4.4.3.def
```

# Launch Rstudio from the HPC

Rstudio server can be hosted on the HPC and accessed from your browser if you are inside the firewall. You can submit the `launch_rstudio_server.sh` to SLURM 
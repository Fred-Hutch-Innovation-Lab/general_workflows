# These are old notes, not sure if they work
Rstudio apptainer --ip=$(hostname) --port=$(fhfreeport)

apptainer exec --cleanenv \
	--home "/fh/fast/_IRC/FHIL/user/dgratz/rocker/rstudio-tmp" \
	/fh/fast/_IRC/FHIL/user/dgratz/rocker/rstudio_latest.sif \
    rserver --www-port $(fhfreeport) \
            --auth-none=0 \
            --auth-pam-helper-path=pam-helper \
            --auth-stay-signed-in-days=30 \
            --auth-timeout-minutes=0 \
            --server-user=${APPTAINERENV_USER}


apptainer exec --cleanenv --home ${RSTUDIO_CWD} ${RSTUDIO_CWD}/${RSTUDIO_SIF} \
    rserver --www-port $(fhfreeport) \
            --auth-none=0 \
            --auth-pam-helper-path=pam-helper \
            --auth-stay-signed-in-days=30 \
            --auth-timeout-minutes=0 \
            --rsession-path=/etc/rstudio/rsession.sh \
            --server-user=${APPTAINERENV_USER}
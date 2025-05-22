#!/bin/bash
ml nextflow
ml Apptainer

SLURM_OPTS="--job-name=spaceranger \
             --output=sbatch.out \
             --error=sbatch.err \
             --nodes=1 \
             --ntasks=1 \
             --cpus-per-task=16 \
             --time=48:00:00 \
             --mail-type=begin \
             --mail-type=end \
             --mail-type=fail \
             --mail-user=dgratz@fredhutch.org"

sbatch $SLURM_OPTS \
            --wrap "
                nextflow run nf-core/spatialvi -r dev \
                    -profile apptainer \
                    --input samplesheet.csv \
                    --spaceranger_probeset /shared/ngs/illumina/ysu2/reference/Visium_Human_Transcriptome_Probe_Set_v2.0_GRCh38_TRAV_WPRE.csv \
                    --spaceranger_reference /shared/ngs/illumina/ysu2/reference/refdata-gex-GRCh38-2020_TRAV_WPRE/ \
                    --outdir spaceranger_out \
                    --email dgratz@fredhutch.org
                    "

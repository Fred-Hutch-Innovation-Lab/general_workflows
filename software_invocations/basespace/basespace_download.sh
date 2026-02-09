#!/usr/bin/env bash

projectID="488002528"

module load BaseSpaceCLI
bs -c ./basespace_config.cfg download project --id $projectID --extension=fastq.gz -o ./${projectID}_fastqs
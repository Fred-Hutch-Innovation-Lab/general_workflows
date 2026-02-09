#!/bin/bash

# R1 = 1, R2 = 2
# 3 = sample name
# 4 = outdir
# 5 tagpattern
datadir="$1"

function run_mixcr {
    mixcr align \
        --preset generic-amplicon-with-umi \
        --species hsa \
        --dna \
        --floating-left-alignment-boundary \
        --floating-right-alignment-boundary J \
        --tag-pattern "^(R1:*)\^(UMI:N{18})(R2:*)" \
        --report $4/$3.report.txt \
        --json-report $4/$3.report.json \
        $1 \
        $2 \
        $4/$3.vdjca 

    mixcr -Xmx40g refineTagsAndSort \
        --report $4/$3.refineTags.report.txt \
        --json-report $4/$3.refineTags.report.json \
        $4/$3.vdjca \
        $4/$3.refined.vdjca 
    
    mixcr -Xmx40g assemble \
        -OassemblingFeatures="CDR3" \
        -OseparateByC=true \
        -OseparateByJ=true \
        -OseparateByV=true \
        --report $4/$3.assembly.report.txt \
        --json-report $4/$3.assembly.report.json \
        $4/$3.refined.vdjca \
        $4/$3.clns 

    mixcr exportClones \
        -uniqueTagCount UMI \
        $4/$3.clns \
        $4/$3.tsv 

    mixcr qc \
        $4/$3.clns \
        $4/$3.qc.txt 

}

function loop_files {
    for r1 in $datadir/fastqs/*R1*.fastq.gz;
        do filename=$(basename $r1);
        samplename=$(echo $filename | sed -E 's/_S[0-9]+.*//');
        r2="${datadir}/fastqs/${samplename}*R2_001.fastq.gz"
        outdir="${datadir}/mixcr_outputs/${samplename}";
        # mkdir $outdir;
        # echo $samplename
        run_mixcr $r1 $r2 $samplename $outdir;
    done
}
loop_files 

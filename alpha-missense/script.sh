#!/bin/bash

wget -nc https://storage.googleapis.com/dm_alphamissense/AlphaMissense_hg38.tsv.gz

GENEBE_CLIENT_JAR=/ssd2/pio/safessd/workspace/workspace.4141/GeneBeClient/target/GeneBeClient-0.0.1-a.9.jar

java -jar $GENEBE_CLIENT_JAR annotation create-from-tsv \
    --input AlphaMissense_hg38.tsv.gz \
    --name "alpha-missense" \
    --owner @genebe \
    --version 0.1.0 \
    --skip 4 \
    --header chr pos ref alt genome uniprot_id transcript_id protein_variant am_pathogenicity am_class \
    --columns am_pathogenicity:FLOAT32 am_class:TEXT

#!/bin/bash
set -e # fail if any fails


source ../_utils/download_genebe.sh

echo "Downloading the REVEL data"
wget -nc https://rothsj06.dmz.hpc.mssm.edu/revel-v1.3_all_chromosomes.zip

unzip revel-v1.3_all_chromosomes.zip
# remove unneeded columns, remove pos that is equal to .
cat revel_with_transcript_ids | cut -f1,3,4,5,8 -d, | grep -v -F ',.,' > revel_hg38.csv

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --separator , \
    --owner @genebe \
    --name revel \
    --version 0.0.1-alpha \
    --title REVEL \
    --columns grch38_pos/pos:int32 \
    --input revel_hg38.csv

# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/revel:0.0.1-alpha --public true

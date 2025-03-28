#!/bin/bash
set -e # fail if any fails

GENOME=/data/reference-seq/hg38/hg38.fa

source ../_utils/download_genebe.sh

echo "Downloading the GnomAD3 mito file"

if [ ! -f input.tsv ]; then
    wget https://storage.googleapis.com/gcp-public-data--gnomad/release/3.1/vcf/genomes/gnomad.genomes.v3.1.sites.chrM.reduced_annotations.tsv -O input.tsv
fi

echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name gnomad3-mito \
    --version 0.0.1-3.1.2 \
    --title "GnomAD Mitochondrial data" \
    --has-header true \
    --columns chromosome/chr:TEXT position/pos:INT32 \
    --input input.tsv \
    --species homo_sapiens \
    --genome GRCh38 \
    --force


# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/gnomad-genomes4:0.0.1-4.1.0 --public true
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/gnomad-exomes4:0.0.1-4.1.0 --public true

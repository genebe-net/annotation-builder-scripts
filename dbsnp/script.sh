#!/bin/bash
set -e # fail if any fails

GENOME=/data/reference-seq/hg38/hg38.fa

source ../_utils/download_genebe.sh

echo "Downloading the newest dbSNP VCF file"
wget -nc https://ftp.ncbi.nih.gov/snp/latest_release/VCF/GCF_000001405.40.gz

echo "Normalize & convert to tsv"
zcat GCF_000001405.40.gz \
| sed -e 's/^NC_0000\([0-9][0-9]\)\.[0-9]*/\1/' \
| sed -e 's/^0//' -e 's/^23/X/' -e 's/^24/Y/' -e 's/NC_012920\.[0-9]*/M/' \
| grep -v -e '^NW_' -e '^NT_'  \
| sed -e 's!^\([0-9XYM][0-9]*\)\t!chr\1\t!' \
| bcftools norm --multiallelics -any  --check-ref s -f $GENOME - \
| sed -e 's!^chr!!' \
| bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%INFO/RS\n' \
| awk 'BEGIN {print "chr\tpos\tref\talt\trs"} {print}' \
| gzip > GCF_000001405.40.tsv.gz

echo "Create the database"
java -jar $GENEBE_CLIENT_JAR annotation create-from-tsv \
    --input GCF_000001405.40.tsv.gz \
    --name "dbsnp" \
    --owner @genebe \
    --version 0.0.1-156.1 \
    --species homo_sapiens \
    --genome GRCh38 \
    --title "The Single Nucleotide Polymorphism Database"

# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/dbsnp:0.0.1-156.1 --public true

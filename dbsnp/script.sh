#!/bin/bash
set -e # fail if any fails

GENOME=/data/reference-seq/hg38/hg38.fa

source ../_utils/download_genebe.sh

echo "Downloading the newest dbSNP VCF file"
wget -nc https://ftp.ncbi.nih.gov/snp/latest_release/VCF/GCF_000001405.40.gz

echo "I replace the header of the input vcf to have ##contig data populated"
echo "I also replace NC_ codes with chr"

if [ ! -f GCF_000001405.40.tsv.bz2 ]; then
    echo "Normalize & convert to tsv"
    (cat head.vcf; zcat GCF_000001405.40.gz | grep -v -E '^#') \
    | sed -e 's/^NC_0000\([0-9][0-9]\)\.[0-9]*/\1/' \
    | sed -e 's/^0//' -e 's/^23/X/' -e 's/^24/Y/' -e 's/NC_012920\.[0-9]*/M/' \
    | grep -v -e '^NW_' -e '^NT_'  \
    | sed -e 's!^\([0-9XYM][0-9]*\)\t!chr\1\t!' \
    | bcftools norm --multiallelics -any  --check-ref s -f $GENOME - \
    | sed -e 's!^chr!!' \
    | bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%INFO/RS\n' \
    | awk 'BEGIN {print "chr\tpos\tref\talt\trs"} {print}' \
    | bzip2 > GCF_000001405.40.tsv.bz2
fi

echo "Create the database, I will use PySpark for this task. Ensure to provide the Spark environment."
# Directory for virtual environment
VENV_DIR=".venv"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $VENV_DIR
fi

# Activate virtual environment
source $VENV_DIR/bin/activate

# Install requirements
echo "Installing requirements..."
pip install -r requirements.txt

# Run your Python script
python script.py --input GCF_000001405.40.tsv.bz2 --output GCF_000001405.40.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input GCF_000001405.40.parquet \
    --name dbsnp \
    --owner @genebe \
    --version 0.0.1-157 \
    --title "dbSNP" \
    --species homo_sapies \
    --genome GRCh38


# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/dbsnp:0.0.1-156.1 --public true

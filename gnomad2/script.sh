#!/bin/bash
set -e # fail if any fails

GENOME=/data/reference-seq/hg38/hg38.fa

source ../_utils/download_genebe.sh

echo "Downloading the GnomAD2 VCF file, exomes"
wget -nc https://storage.googleapis.com/gcp-public-data--gnomad/release/2.1.1/vcf/exomes/gnomad.exomes.r2.1.1.sites.vcf.bgz
echo "Downloading the GnomAD2 VCF file, genomes (HUGE FILE!)"
wget -nc https://storage.googleapis.com/gcp-public-data--gnomad/release/2.1.1/vcf/genomes/gnomad.genomes.r2.1.1.sites.vcf.bgz


vcf_to_tsv() {
    local FIELDS_FILE="$1"
    local INPUT="$2"

    local FIELDS
    FIELDS=$(tr '\n' ' ' < "$FIELDS_FILE")

    local OUTPUT
    OUTPUT="$(basename "$INPUT").tsv.bz2"

    echo "$FIELDS" | sed -e 's/ /\t/g' | sed -e 's/ /\t/g' | sed -E 's/^CHROM/chr/; s/POS/pos/; s/REF/ref/; s/ALT/alt/; s/INFO\///g' | lbzip2 > "$OUTPUT"
    bcftools query -f "$(echo "$FIELDS" | sed -e 's/ $//' | sed -e 's/ /\\t%/g' | sed -e 's/^/%/' )\n" "$INPUT" | lbzip2 >> "$OUTPUT"
}

echo "Convert vcf files to tsv with only needed columns"

vcf_to_tsv fields-exomes gnomad.exomes.r2.1.1.sites.vcf.bgz
vcf_to_tsv fields-genomes gnomad.genomes.r2.1.1.sites.vcf.bgz


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
python script.py --input gnomad.exomes.r2.1.1.sites.vcf.bgz.tsv.bz2 --output gnomad.exomes.r2.1.1.sites.parquet
python script.py --input gnomad.genomes.r2.1.1.sites.vcf.bgz.tsv.bz2 --output gnomad.genomes.r2.1.1.sites.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input gnomad.exomes.r2.1.1.sites.parquet \
    --name gnomad-exomes2 \
    --owner @genebe \
    --version 0.0.1-2.1.1 \
    --title "Genome Aggregation Database Exomes 2.1.1, GRCh37, " \
    --species homo_sapies \
    --genome GRCh37

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input gnomad.genomes.r2.1.1.sites.parquet \
    --name gnomad-genomes2 \
    --owner @genebe \
    --version 0.0.1-2.1.1 \
    --title "Genome Aggregation Database Genomes 2.1.1, GRCh37, " \
    --species homo_sapies \
    --genome GRCh37



# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/dbsnp:0.0.1-156.1 --public true

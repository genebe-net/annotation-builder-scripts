#!/bin/bash
set -e # fail if any fails

GENOME=/data/reference-seq/hg38/hg38.fa

source ../_utils/download_genebe.sh

echo "Downloading the GnomAD2 VCF file, exomes"

for CHR in {1..22} X Y; do
    # download if not exists
    if [ ! -f gnomad.exomes.v4.1.sites.chr${CHR}.vcf.bgz ]; then
        wget https://storage.googleapis.com/gcp-public-data--gnomad/release/4.1/vcf/exomes/gnomad.exomes.v4.1.sites.chr${CHR}.vcf.bgz
    fi
done

echo "Downloading the GnomAD2 VCF file, genomes (HUGE FILES!)"
for CHR in {1..22} X Y; do
    # download if not exists
    if [ ! -f gnomad.genomes.v4.1.sites.chr${CHR}.vcf.bgz ]; then
        wget https://storage.googleapis.com/gcp-public-data--gnomad/release/4.1/vcf/genomes/gnomad.genomes.v4.1.sites.chr${CHR}.vcf.bgz
    fi
done

vcf_to_tsv() {
    local FIELDS_FILE="$1"
    local INPUT="$2"

    local FIELDS
    FIELDS=$(tr '\n' ' ' < "$FIELDS_FILE")

    local OUTPUT
    OUTPUT="$(basename "$INPUT").tsv.bz2"

    echo "$FIELDS" | sed -e 's/ /\t/g' | sed -e 's/ /\t/g' | sed -E 's/^CHROM/chr/; s/POS/pos/; s/REF/ref/; s/ALT/alt/; s/INFO\///g' | sed 's/[[:space:]]*$//' | lbzip2 > "$OUTPUT"
    bcftools query -f "$(echo "$FIELDS" | sed -e 's/ $//' | sed -e 's/ /\\t%/g' | sed -e 's/^/%/' )\n" "$INPUT" | lbzip2 >> "$OUTPUT"
}

echo "Convert vcf files to tsv with only needed columns"

for VCF in gnomad.exomes.v4.1.sites.chr{{1..22},X,Y}.vcf.bgz; do
    # if not exists
    if [ ! -f "$(basename "$VCF").tsv.bz2" ]; then
        vcf_to_tsv fields-exomes "$VCF"
    fi
done
for VCF in gnomad.genomes.v4.1.sites.chr{{1..22},X,Y}.vcf.bgz; do
    # if not exists
    if [ ! -f "$(basename "$VCF").tsv.bz2" ]; then
        vcf_to_tsv fields-genomes "$VCF"
    fi
done


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
python script.py --input 'gnomad.exomes.*.vcf.bgz.tsv.bz2' --output gnomad.exomes.sites.parquet
python script.py --input 'gnomad.genomes.*.vcf.bgz.tsv.bz2' --output gnomad.genomes.sites.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input gnomad.exomes.sites.parquet \
    --name gnomad-exomes4 \
    --owner @genebe \
    --version 0.0.1-4.1.0 \
    --title "Genome Aggregation Database Exomes 4.1.0, GRCh38, " \
    --species homo_sapies \
    --genome GRCh38

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input gnomad.genomes.sites.parquet \
    --name gnomad-genomes4 \
    --owner @genebe \
    --version 0.0.1-4.1.0 \
    --title "Genome Aggregation Database Genomes 4.1.0, GRCh38, " \
    --species homo_sapies \
    --genome GRCh38



# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/gnomad-genomes4:0.0.1-4.1.0 --public true
java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/gnomad-exomes4:0.0.1-4.1.0 --public true

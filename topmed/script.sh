#!/bin/bash
set -e # fail if any fails

GENOME=/data/reference-seq/hg38/hg38.fa

source ../_utils/download_genebe.sh

if [ -f chr1.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr2.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr3.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr4.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr5.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr6.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr7.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr8.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr9.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr10.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr11.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr12.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr13.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr14.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr15.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr16.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr17.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr18.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr19.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr20.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr21.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chr22.TOPMed_freeze_8.all.vcf.gz ] && \
   [ -f chrX.TOPMed_freeze_8.all.vcf.gz ]; then
    echo "All files exist"
else
    echo "You have to download data from https://legacy.bravo.sph.umich.edu/freeze8/hg38/downloads and put in this directory"
    exit 1
fi





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

for file in chr{1..22}.TOPMed_freeze_8.all.vcf.gz chrX.TOPMed_freeze_8.all.vcf.gz ; do
    if [ -f "$(basename "$file").tsv.bz2" ]; then
        echo "Skipping $file"
    else
        vcf_to_tsv fields-topmed $file
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
python script.py --input '*.tsv.bz2' --output topmed.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input topmed.parquet \
    --name topmed \
    --owner @genebe \
    --version 0.0.1-freeze.8 \
    --title "Topmed " \
    --species homo_sapies \
    --genome GRCh38

# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/dbsnp:0.0.1-156.1 --public true

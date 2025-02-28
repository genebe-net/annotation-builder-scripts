#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh

echo "Checking source data"

if [ ! -f "GRCh38.tgz" ]; then
    echo "Download GRCh38.tgz from https://fenglab.chpc.utah.edu/download/GRCh38.tgz"
    wget https://fenglab.chpc.utah.edu/download/GRCh38.tgz
fi
if [ ! -f "GRCh37.tgz" ]; then
    echo "Download GRCh37.tgz from https://fenglab.chpc.utah.edu/download/GRCh37.tgz"
    wget https://fenglab.chpc.utah.edu/download/GRCh37.tgz
fi

echo "Extracting source data"
if [ ! -d "GRCh38" ]; then
    tar -xvzf GRCh38.tgz GRCh38/BayesDel_nsfp33a_noAF/
fi
if [ ! -d "GRCh37" ]; then
    tar -xvzf GRCh37.tgz GRCh37/BayesDel_nsfp33a_noAF/
fi

# run vAnnBase from VICTOR package

echo "TODO: create a whole genome SNV VCF file and using VICTOR annotate it with BayesDel_nsfp33a_noAF"
echo "This was done for GRCh38 to create the BayesDel_noAF_full_genome_precomputed_hg38.tsv.bz2 I use below"
echo "But the code was lost..."
exit 1

# utils/vAnnBase /home/pio/Downloads/Sample_NA12878_30mln.hg38.hc2.vcf.gz --add-info --ann=BayesDel_nsfp33a_noAF -x=3 --min=-1.5 --step=0.01 --indel=max --padding=1 --genome GRCh38 > /tmp/out.vcf


# Directory for virtual environment
VENV_DIR=".venv"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $VENV_DIR


    # Activate virtual environment
    source $VENV_DIR/bin/activate

    # Install requirements
    echo "Installing requirements..."
    pip install -r requirements.txt
else
    source $VENV_DIR/bin/activate
fi

echo "Converting tsv to parquet"

# Run your Python script
python script.py --input BayesDel_noAF_full_genome_precomputed_hg38.tsv.bz2 --output bd.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input bd.parquet \
    --name bayesdel-hg38 \
    --owner @genebe \
    --version 0.0.1 \
    --title "Precomputed BayesDel noAF scores" \
    --species homo_sapiens \
    --genome GRCh38

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
echo "java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/bayesdel-hg38:0.0.1 --public true"

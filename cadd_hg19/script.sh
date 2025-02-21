#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh

echo "Downloading the CADD tsv file"

if [ ! -f "cadd.GRCh37.tsv.gz" ]; then
    wget https://krishna.gs.washington.edu/download/CADD/v1.7/GRCh37/whole_genome_SNVs.tsv.gz -O cadd.GRCh37.tsv.gz
fi

echo "Convert gzip to bzip2 for multithread processing in Spark"

if [ ! -f "cadd.GRCh37.tsv.bz2" ]; then
    zcat cadd.GRCh37.tsv.gz | lbzip2 > cadd.GRCh37.tsv.bz2
fi



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
    # Activate virtual environment
    source $VENV_DIR/bin/activate
fi

echo "Converting tsv to parquet"


# Run your Python script
python script.py --input cadd.GRCh37.tsv.bz2 --output cadd.GRCh37.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input cadd.GRCh37.parquet \
    --name cadd_hg37 \
    --owner @genebe \
    --version 0.0.1-1.7.0 \
    --title "CADD is a tool for scoring the deleteriousness" \
    --species homo_sapiens \
    --genome GRCh37

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/cadd_hg37:0.0.1-1.7.0 --public true

#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh

echo "Checking source data"

if [ ! -f "MT2021_allPredictions_20250217.tsv.gz" ]; then
    echo "There is no input data, please download it by contacting MutationTaster authors"
    exit 1
fi

if [ ! -f input.tsv.bz2 ]; then
    echo "Converting tsv to bz2 for faster processing in Spark"
    zcat MT2021_allPredictions_20250217.tsv.gz | bzip2 > input.tsv.bz2
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
    source $VENV_DIR/bin/activate
fi

echo "Converting tsv to parquet"

# Run your Python script
python script.py --input input.tsv.bz2 --output mt.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input mt.parquet \
    --name mutation-taster \
    --owner @genebe \
    --version 0.0.1-20250217 \
    --title "Precomputed MutationTaster 2021 Annotations for Genetic Variant Interpretation" \
    --species homo_sapiens \
    --genome GRCh37

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
echo "java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/mutation-taster:0.0.1-20250217 --public true"

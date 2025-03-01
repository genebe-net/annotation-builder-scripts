#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh

echo "Downloading the gpn-msa tsv file"

if [ ! -f "scores.tsv.bgz" ]; then
    wget wget https://huggingface.co/datasets/songlab/gpn-msa-hg38-scores/resolve/main/scores.tsv.bgz
fi

echo "Convert gzip to bzip2 for multithread processing in Spark"

if [ ! -f "scores.tsv.bz2" ]; then
    zcat scores.tsv.bgz | lbzip2 > scores.tsv.bz2
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
python script.py --input scores.tsv.bz2 --output scores.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

NAME=gpn-msa
VERSION=0.0.1

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input scores.parquet \
    --name $NAME \
    --owner @genebe \
    --version $VERSION \
    --title "GPN-MSA - genomic pretrained network with multiple-sequence alignment" \
    --species homo_sapiens \
    --genome GRCh38

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/$NAME:$VERSION --public true

#!/bin/bash

echo "Download data from wget https://helix-research-public.s3.amazonaws.com/mito/HelixMTdb_20200327.tsv"

set -e # fail if any fails

source ../_utils/download_genebe.sh

if [ ! -f HelixMTdb_20200327.tsv ]; then
    wget https://helix-research-public.s3.amazonaws.com/mito/HelixMTdb_20200327.tsv
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

echo "Making the liftover, I will call python GeneBe script"

# Run your Python script
if [ ! -f cm_all_download_hg38.tsv ]; then
    python script.py --input HelixMTdb_20200327.tsv --output ready.tsv
fi


# Deactivate virtual environment
deactivate

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name helixmtdb \
    --version 0.0.1 \
    --title "HelixMtDB" \
    --input ready.tsv \
    --genome GRCh38

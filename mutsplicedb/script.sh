#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh

DATE=$(date '+%Y%m%d')

echo "Download https://brb.nci.nih.gov/cgi-bin/splicing/splicing_main.cgi and save as MutSpliceDB.csv"
if [ ! -f MutSpliceDB.csv ]; then
    echo "No MutSpliceDB.csv file, exiting"
    exit 1
else
    echo "MutSpliceDB.csv already exists"
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

echo "Call python GeneBe script to convert MutSpliceDB.csv to tsv and translate HGVS to genomic coordinates"

# Run your Python script
if [ ! -f MutSpliceDB_hg38.tsv ]; then
    python script.py --input MutSpliceDB.csv --output MutSpliceDB_hg38.tsv
fi


# Deactivate virtual environment
deactivate

VERSION="0.0.1-$DATE"

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name mutsplicedb-hg38 \
    --version $VERSION \
    --title "MutSpliceDB HG38" \
    --input MutSpliceDB_hg38.tsv \
    --genome GRCh38 \
    --force

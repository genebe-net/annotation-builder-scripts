#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh


echo "Downloading cardioboost-cardiomyopathies and cardioboost-arrythmias. You may get your own download links from https://www.cardiodb.org/cardioboost/ "
if [ ! -f cm_all_download.tsv ]; then
    echo "Downloading cardioboost-cardiomyopathies"
    wget -v https://www.cardiodb.org/cardioboost/session/f1ea3f5d94654b154644a89490f3b2a0/download/cm_all_download?w= -o cm_all_download.tsv
fi

if [ ! -f arm_all_download.tsv ]; then
    echo "Downloading cardioboost-arrythmias"
    wget -v https://www.cardiodb.org/cardioboost/session/f1ea3f5d94654b154644a89490f3b2a0/download/arm_all_download?w= -o arm_all_download.tsv
fi

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name cardioboost-cardiomyopathies-hg19 \
    --version 0.0.1 \
    --title "CardioBoost Cardiomyopathies" \
    --columns chrom/chr:text \
    --excluded-columns gene hgvsc hgvsp classification \
    --input cm_all_download.tsv \
    --genome GRCh37

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name cardioboost-arrhythmias-hg19 \
    --version 0.0.1 \
    --title "CardioBoost Arrhythmias" \
    --columns chrom/chr:text \
    --excluded-columns gene hgvsc hgvsp classification \
    --input arm_all_download.tsv \
    --genome GRCh37

echo "Done for GRCh37, now for GRCh38 we need to do the liftover, let's use the GeneBe liftover tool"

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
    python script.py --input cm_all_download.tsv --output cm_all_download_hg38.tsv
fi

if [ ! -f arm_all_download_hg38.tsv ]; then
    python script.py --input arm_all_download.tsv --output arm_all_download_hg38.tsv
fi

# Deactivate virtual environment
deactivate

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name cardioboost-cardiomyopathies-hg38 \
    --version 0.0.1 \
    --title "CardioBoost Cardiomyopathies" \
    --excluded-columns gene hgvsc hgvsp classification \
    --input cm_all_download_hg38.tsv \
    --genome GRCh38

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name cardioboost-arrhythmias-hg38 \
    --version 0.0.1 \
    --title "CardioBoost Arrhythmias" \
    --excluded-columns gene hgvsc hgvsp classification \
    --input arm_all_download_hg38.tsv \
    --genome GRCh38

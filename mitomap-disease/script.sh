#!/bin/bash
set -e # fail if any fails


source ../_utils/download_genebe.sh

TODAY=$(date +"%Y%m%d")

echo "Downloading the mitomap disease data"
if [ -f mitomap_disease-$TODAY.tsv ]; then
    echo "File mitomap_disease-$TODAY.tsv already exists. Skip download."
else
    wget https://www.mitomap.org/cgi-bin/disease.cgi -O mitomap_disease-$TODAY.tsv
fi


# add the chr column; replace non breaking space with space
awk 'BEGIN{OFS="\t"} NR==1{print $0, "chr"; next} {print $0, "M"}' mitomap_disease-$TODAY.tsv \
    | tr '\240' ' ' > with_chr.tsv

echo "Process input data. Mitotip gbfreq is in percentage, so we need to divide by 100"
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
python script.py --input 'with_chr.tsv' --output ready.tsv

# Deactivate virtual environment
deactivate


NAME=mitomap-disease

VERSION=0.0.1-$TODAY

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name $NAME \
    --version $VERSION \
    --title "Mitomap Disease" \
    --columns pos:int32 chr:text ref:text alt:text pubmed_ids:text gbcnt:int32 gbfreq:float32 \
    --excluded-columns id aachange \
    --input ready.tsv \
    --force

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
echo "java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/$NAME:$VERSION --public true"
java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/$NAME:$VERSION --public true

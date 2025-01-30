#!/bin/bash
set -e # fail if any fails


source ../_utils/download_genebe.sh

echo "Downloading the VARITY data"
wget -nc http://varity.varianteffect.org/downloads/varity_all_predictions.tar.gz

tar -xf varity_all_predictions.tar.gz

# remove unneeded columns, remove pos that is equal to .
cat varity_all_predictions.txt | cut -f1-4,9-12  > varity-ready.csv

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name varity \
    --version 0.0.1 \
    --title VARITY \
    --columns nt_pos/pos:int32 nt_ref/ref:text nt_alt/alt:text \
    --input varity-ready.csv

# echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
# java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/varity:0.0.1 --public true

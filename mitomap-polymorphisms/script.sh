#!/bin/bash
set -e # fail if any fails


source ../_utils/download_genebe.sh

TODAY=$(date +"%Y%m%d")

echo "Downloading the mitomap polymorphisms data"
if [ -f mitomap_polymorphisms-$TODAY.tsv ]; then
    echo "File mitomap_polymorphisms-$TODAY.tsv already exists. Skip download."
else
    wget https://mitomap.org/cgi-bin/polymorphisms.cgi -O mitomap_polymorphisms-$TODAY.tsv
fi


# add the chr column
awk 'BEGIN{OFS="\t"} NR==1{print $0, "chr"; next} {print $0, "M"}' mitomap_polymorphisms-$TODAY.tsv > ready.tsv

NAME=mitomap-polymorphisms

VERSION=0.0.1-$TODAY

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name $NAME \
    --version $VERSION \
    --title "Mitomap Polymorphisms" \
    --columns pos:int32 chr:text ref:text alt:text pubmed_ids:text gbcnt:int32 gbfreq:float32 \
    --excluded-columns id aachange \
    --input ready.tsv

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
echo "java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/$NAME:$VERSION --public true"

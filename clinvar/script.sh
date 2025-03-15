#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh

echo "Downloading the newest ClinVar VCF file"

wget -nc  https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar.vcf.gz -O clinvar.vcf.gz
CLINVAR_DATE=$(zcat clinvar.vcf.gz | grep '##fileDate=' | head -n1 | cut -f2 -d= | tr --delete '-')
mv clinvar.vcf.gz clinvar-$CLINVAR_DATE.vcf.gz

echo "ClinVar date: $CLINVAR_DATE"

echo "Removing commas from CLNREVSTAT, ONCREVSTAT, SCIREVSTAT, otherwise they are read as lists and incorrectly parsed"
zcat clinvar-$CLINVAR_DATE.vcf.gz \
    | sed ':a; s/\(CLNREVSTAT=[^;]*\),/\1/; ta' \
    | sed ':a; s/\(ONCREVSTAT=[^;]*\),/\1/; ta' \
    | sed ':a; s/\(SCIREVSTAT=[^;]*\),/\1/; ta' \
    | gzip > clinvar-processed.vcf.gz

echo "Converting ClinVar VCF to GeneBe Annotation"

VERSION=0.0.2-$CLINVAR_DATE
NAME=clinvar
OWNER=@genebe

java -jar $GENEBE_CLIENT_JAR annotation create-from-vcf \
    --input-vcf clinvar-processed.vcf.gz \
    --name $NAME \
    --owner $OWNER \
    --version $VERSION \
    --columns CLNDN:TEXT CLNREVSTAT CLNSIG CLNSIGCONF ONCDN ONC ONCREVSTAT ONCCONF SCIDN SCI SCIREVSTAT ORIGIN \
    --title "A Public Database of Genetic Variants" \
    --species homo_sapies \
    --genome GRCh38 \
    --readme-source ./template/README.md \
    --license-source ./template/LICENSE.txt \
    --metadata-source ./description.toml

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
java -jar $GENEBE_CLIENT_JAR annotation push --id $OWNER/$NAME:$VERSION --public true

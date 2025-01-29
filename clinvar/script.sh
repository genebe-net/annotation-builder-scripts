#!/bin/bash
set -e # fail if any fails

source ../_utils/download_genebe.sh

echo "Downloading the newest ClinVar VCF file"

wget -nc  https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar.vcf.gz -O clinvar.vcf.gz
CLINVAR_DATE=$(zcat clinvar.vcf.gz | grep '##fileDate=' | head -n1 | cut -f2 -d= | tr --delete '-')
mv clinvar.vcf.gz clinvar-$CLINVAR_DATE.vcf.gz

echo "ClinVar date: $CLINVAR_DATE"

echo "Converting ClinVar VCF to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-vcf \
    --input-vcf clinvar-$CLINVAR_DATE.vcf.gz \
    --name clinvar \
    --owner @genebe \
    --version 0.0.1-$CLINVAR_DATE \
    --columns CLNDN:TEXT CLNREVSTAT CLNSIG ONCDN ONC ONCREVSTAT SCIDN SCI SCIREVSTAT \
    --title "A Public Database of Genetic Variants" \
    --species homo_sapies \
    --genome GRCh38 \
    --readme-source ./template/README.md \
    --license-source ./template/LICENSE.txt \
    --metadata-source ./description.toml

echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/clinvar:0.0.1-$CLINVAR_DATE --public true

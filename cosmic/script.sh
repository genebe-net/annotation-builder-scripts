#!/bin/bash

VERSION=101
echo "Version is set to $VERSION"
echo "Download data from https://cancer.sanger.ac.uk/cosmic/download/cosmic/v$VERSION/noncodingvariantsvcfnormal and https://cancer.sanger.ac.uk/cosmic/download/cosmic/v$VERSION/genomescreensmutantvcfnormal . Extract them here."

set -e # fail if any fails

source ../_utils/download_genebe.sh


for GENOME in GRCh37 GRCh38; do
    # if GENOME is GRCh37, then GENOME_HG is hg19, otherwise hg38; use bash if / else statements
    GENOME_HG=$(if [ $GENOME == "GRCh37" ]; then echo "hg19"; else echo "hg38"; fi)

    echo "Processing $GENOME"
    for TYPE in GenomeScreensMutant NonCodingVariants; do
        echo "Processing $TYPE"

        if [ $TYPE == "NonCodingVariants" ]; then
            SAMPLE_COUNT_COLUMN_NAME="SAMPLE_COUNT"
        else
            SAMPLE_COUNT_COLUMN_NAME="GENOME_SCREEN_SAMPLE_COUNT"
        fi

        # f.ex. Cosmic_GenomeScreensMutant_Normal_v101_GRCh38.vcf.gz
        INPUT_FILE=Cosmic_${TYPE}_Normal_v${VERSION}_$GENOME.vcf.gz
        if [ ! -f $INPUT_FILE ]; then
            echo "There is no $INPUT_FILE, please download it from https://cancer.sanger.ac.uk/cosmic/download/cosmic"
            exit 1
        fi

        # deduplicate on ID
        zcat $INPUT_FILE \
            | awk '!/^#/ { if (!seen[$3]++) print; next } 1' \
            | gzip > Cosmic_${TYPE}_Normal_v${VERSION}_${GENOME}_ready.vcf.gz

        # convert NAME to lowercase
        NAME=$(echo cosmic-${TYPE}-${GENOME_HG} | tr '[:upper:]' '[:lower:]')

        java -jar $GENEBE_CLIENT_JAR annotation create-from-vcf \
            --owner @genebe \
            --name $NAME \
            --version 0.0.1-${VERSION} \
            --title "COSMIC v$VERSION $TYPE $GENOME" \
            --input-vcf Cosmic_${TYPE}_Normal_v${VERSION}_${GENOME}_ready.vcf.gz \
            --columns $SAMPLE_COUNT_COLUMN_NAME TIER ID \
            --genome $GENOME
    done


done

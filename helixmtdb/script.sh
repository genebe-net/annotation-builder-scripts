#!/bin/bash

echo "Download data from wget https://helix-research-public.s3.amazonaws.com/mito/HelixMTdb_20200327.tsv"

set -e # fail if any fails

source ../_utils/download_genebe.sh

if [ ! -f HelixMTdb_20200327.tsv ]; then
    wget https://helix-research-public.s3.amazonaws.com/mito/HelixMTdb_20200327.tsv
fi


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

        # deduplicate on ID; add ID to the INFO columns
        zcat $INPUT_FILE \
            | awk '!/^#/ { if (!seen[$3]++) print; next } 1' \
            | /usr/bin/bcftools annotate -c ID,INFO/CosmicId -h <(echo '##INFO=<ID=CosmicId,Number=1,Type=String,Description="COSMIC ID">') -Oz -o Cosmic_${TYPE}_Normal_v${VERSION}_${GENOME}_ready.vcf.gz

        # convert NAME to lowercase
        NAME=$(echo cosmic-${TYPE}-${GENOME_HG} | tr '[:upper:]' '[:lower:]')

        java -jar $GENEBE_CLIENT_JAR annotation create-from-vcf \
            --owner @genebe \
            --name $NAME \
            --version 0.0.1-${VERSION} \
            --title "COSMIC v$VERSION $TYPE $GENOME" \
            --input-vcf Cosmic_${TYPE}_Normal_v${VERSION}_${GENOME}_ready.vcf.gz \
            --columns $SAMPLE_COUNT_COLUMN_NAME TIER \
            --genome $GENOME
    done


done

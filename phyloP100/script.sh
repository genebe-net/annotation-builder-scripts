#!/bin/bash
set -e # fail if any fails

GENOME=/data/reference-seq/hg38/hg38.fa

source ../_utils/download_genebe.sh

echo "Downloading the data"
wget -nc https://hgdownload.cse.ucsc.edu/goldenpath/hg38/phyloP100way/hg38.phyloP100way.bw
wget -nc https://hgdownload.cse.ucsc.edu/goldenpath/hg19/phyloP100way/hg19.100way.phyloP100way.bw

echo "Convert to bedgraph"
../_utils/bigWigToBedGraph hg38.phyloP100way.bw hg38.bedGraph
../_utils/bigWigToBedGraph hg19.100way.phyloP100way.bw hg19.bedGraph

echo "Split multi bp ranges into single positions"
echo -e "chr\tpos\tscore" | bzip2 > hg38.single.bedGraph.bz2
awk '{
    for (i = $2; i < $3; i++)
        print $1, i, i+1, $4
}' hg38.bedGraph | cut -f1,2,4 | bzip2 >> hg38.single.bedGraph.bz2

echo -e "chr\tpos\tscore"| bzip2   > hg19.single.bedGraph.bz2
awk '{
    for (i = $2; i < $3; i++)
        print $1, i, i+1, $4
}' hg19.bedGraph | cut -f1,2,4 | bzip2  >> hg19.single.bedGraph.bz2



echo "Create the database, I will use PySpark for this task. Ensure to provide the Spark environment."
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
python script.py --input hg38.single.bedGraph.bz2 --output hg38.parquet
python script.py --input hg19.single.bedGraph.bz2 --output hg19.parquet

# Deactivate virtual environment
deactivate


echo "Converting parquet to GeneBe Annotation"

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input hg38.parquet \
    --name phylop100_hg38 \
    --owner @genebe \
    --version 0.0.1 \
    --title "dbSNP" \
    --species homo_sapies \
    --genome GRCh38

java -jar $GENEBE_CLIENT_JAR annotation create-from-parquet \
    --input hg19.parquet \
    --name phylop100_hg19 \
    --owner @genebe \
    --version 0.0.1 \
    --title "dbSNP" \
    --species homo_sapies \
    --genome GRCh37


echo "Push annotatioin to the hub. I assume you are already logged in GeneBe Hub."
echo "java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/phylop100_hg19:0.0.1 --public true"
echo "java -jar $GENEBE_CLIENT_JAR annotation push --id @genebe/phylop100_hg38:0.0.1 --public true"

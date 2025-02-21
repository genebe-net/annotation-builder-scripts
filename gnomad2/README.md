## GnomAD 2.1.1 exomes and genomes

Create Gnomad Exomes and Genomes for GRCh37 from the 2.1.1 version.

You need a lot of disk space for running this process, estimated 1 TB is needed (input data is over 400 GB).

Run `script.sh`. It:
1. Downloads input data
2. Parses it using `bcftools`, extracts fields listed in `fields` files into tsv files.
3. Convert `tsv` files to `parquet` with python script, using Apache Spark, after setting the environment.

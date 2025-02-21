# Annotation Builder Scripts

A collection of scripts to create, preprocess, and prepare variant annotations for submission to [GeneBe Hub](https://genebe.net/hub).

The scripts presented here allow you to reproduce the preprocessing of publicly available variant annotation databases and convert them to the standard Parquet format, which is compatible with GeneBe Hub. These databases can then be used for VCF file annotation using the [GeneBeClient](https://github.com/pstawinski/genebe-cli).

Since the [format](https://genebe.net/about/hub-format) is standardized and based on [Parquet](https://parquet.apache.org/), it is well-supported across many languages and frameworks. As a result, databases stored in GeneBe Hub can be easily utilized by bioinformaticians. Thanks to the semantic versioning of the databases, staying up to date is simple.

These recipes demonstrate how to import databases originally distributed as `VCF` or `TSV` files using different methods. I encourage you to build your own scripts and contribute new, valuable databases to GeneBe Hub. This repository is also open to pull requests.

## Repository format
For each database (or database group) create a directory with `script.sh` and `README.md` files.

# Dependencies
Some of processes requires:
* java (21+)
* Python (3.10+)
* Apache Spark ( https://spark.apache.org/ 
* )
* bcftools ( https://github.com/samtools/bcftools )
* `bigWigToBedGraph`

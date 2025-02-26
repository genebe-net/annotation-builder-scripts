import argparse
import findspark

findspark.init()
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, udf
from pyspark.sql.types import StructType, StructField, StringType, IntegerType
from pyspark.sql.functions import expr, when, col

# Parse arguments
parser = argparse.ArgumentParser(description="Process input data with PySpark.")
parser.add_argument("--input", required=True, help="Path to input file, input.tsv.bz2")
parser.add_argument(
    "--output", required=True, help="Path to output directory, output.parquet"
)
args = parser.parse_args()

# Initialize Spark session. Be warned: a lot of memory is needed for this task
spark = (
    SparkSession.builder.appName("Phylop100 Processing")
    .config("spark.driver.memory", "64g")
    .config("spark.executor.memory", "64g")
    .getOrCreate()
)

# Read CSV file
df = (
    spark.read.format("csv")
    .option("header", "true")
    .option("inferSchema", True)
    .option("delimiter", "\t")
    .option("nullValue", ".")
    .option("comment", "#")
    .load(args.input)
)


def process_dataframe(df, output_dir):
    df_transformed = (
        df.withColumnRenamed("chr", "_seq")
        .withColumnRenamed("pos", "_pos")
        .withColumn(
            "_seq",
            when(
                col("_seq").startswith("chr"), expr("substring(_seq, 4, length(_seq))")
            ).otherwise(col("_seq")),
        )
        .withColumn("_seq", when(col("_seq") == "MT", "M").otherwise(col("_seq")))
    )

    final_df = df_transformed.dropDuplicates(["_seq", "_pos"])

    (
        final_df.repartition("_seq")
        .sortWithinPartitions("_seq", "_pos")
        .write.option("compression", "zstd")
        .partitionBy("_seq")
        .parquet(output_dir)
    )


process_dataframe(df, args.output)

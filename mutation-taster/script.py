import argparse
import findspark

findspark.init()
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, udf
from pyspark.sql.types import StructType, StructField, StringType, IntegerType
import os
from pyspark.sql import functions as F
from pyspark.sql.window import Window

# Parse arguments
parser = argparse.ArgumentParser(description="Process data with PySpark.")
parser.add_argument("--input", required=True, help="Path to input file, input.tsv.bz2")
parser.add_argument(
    "--output", required=True, help="Path to output directory, output.parquet"
)
args = parser.parse_args()

tmp_dir = os.getenv("SPARK_TMP_DIR", "/tmp")

# Initialize Spark session. Be warned: a lot of memory is needed for this task
spark = (
    SparkSession.builder.appName("Processing")
    .config("spark.driver.memory", "64g")
    .config("spark.executor.memory", "64g")
    .config("spark.local.dir", tmp_dir)
    .getOrCreate()
)

# Read CSV file
data = (
    spark.read.format("csv")
    .option("header", "true")
    .option("inferSchema", True)
    .option("delimiter", "\t")
    .option("nullValue", ".")
    .option("comment", "%")
    .load(args.input)
)

# Rename columns
rename_dict = {"#chromosome": "chr", "position": "pos"}


for old_name, new_name in rename_dict.items():
    data = data.withColumnRenamed(old_name, new_name)

    # Drop unnecessary columns
data = data.drop("ncbi_gene_id_", "ensembl_transcript_stable_id", "model")


# Select the row with the maximum trees_deleterious for each (chr, pos, ref, alt) tuple
# Define a window specification that partitions by the tuple of columns and orders by 'trees_deleterious' descending
window_spec = Window.partitionBy("chr", "pos", "ref", "alt").orderBy(
    F.col("trees_deleterious").desc()
)

# Add a row number for each partition
df_with_row_number = data.withColumn("row_number", F.row_number().over(window_spec))

# Filter the dataframe to keep only the rows where the row number is 1 (the row with the highest 'trees_deleterious' value)
data = df_with_row_number.filter(F.col("row_number") == 1).drop("row_number")


# Rename temp column back to trees_deleterious
data = data.withColumnRenamed("temp_trees_deleterious", "trees_deleterious")


# Define the function to transform the data
def to_spdi(chr_input, pos_input, ref_input, alt_input):
    if not chr_input or pos_input < 0:
        return None, -1, -1, None

    seq = chr_input.lstrip("chr")
    if seq == "MT":
        seq = "M"

    ref = "" if ref_input is None else ref_input
    alt = "" if alt_input is None else alt_input
    vcf_pos = pos_input

    leading_common = 0
    while (
        leading_common < len(ref)
        and leading_common < len(alt)
        and ref[leading_common] == alt[leading_common]
    ):
        leading_common += 1

    ref = ref[leading_common:]
    alt = alt[leading_common:]
    pos = vcf_pos - 1 + leading_common  # Convert to 0-based

    trailing_common = 0
    while (
        len(ref) > trailing_common
        and len(alt) > trailing_common
        and ref[-(trailing_common + 1)] == alt[-(trailing_common + 1)]
    ):
        trailing_common += 1

    ref = ref[: len(ref) - trailing_common]
    alt = alt[: len(alt) - trailing_common]

    return seq, pos, len(ref), alt


# Define UDF with schema
to_spdi_udf = udf(
    to_spdi,
    StructType(
        [
            StructField("_seq", StringType(), True),
            StructField("_pos", IntegerType(), True),
            StructField("_del", IntegerType(), True),
            StructField("_ins", StringType(), True),
        ]
    ),
)


def process_dataframe(df, output_dir):
    df_with_spdi = (
        df.withColumn(
            "spdi", to_spdi_udf(col("chr"), col("pos"), col("ref"), col("alt"))
        )
        .withColumn("_seq", col("spdi").getItem("_seq"))
        .withColumn("_pos", col("spdi").getItem("_pos"))
        .withColumn("_del", col("spdi").getItem("_del"))
        .withColumn("_ins", col("spdi").getItem("_ins"))
        .drop("spdi")
    )

    final_df = df_with_spdi.drop("chr", "pos", "ref", "alt").dropDuplicates(
        ["_seq", "_pos", "_del", "_ins"]
    )

    (
        final_df.repartition("_seq")
        .sortWithinPartitions("_seq", "_pos", "_del", "_ins")
        .write.option("compression", "zstd")
        .partitionBy("_seq")
        .parquet(output_dir)
    )


process_dataframe(data, args.output)

import argparse
import findspark

findspark.init()
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, udf
from pyspark.sql import functions as F
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    IntegerType,
    DoubleType,
    BooleanType,
    FloatType,
)
import os
import numpy as np
from scipy import stats
from glob import glob

# Parse arguments
parser = argparse.ArgumentParser(description="Process input data with PySpark.")
parser.add_argument(
    "--input",
    required=True,
    help="Path to input file, input.tsv.bz2, can be glob like: prefix.*.tsv.bz2",
)
parser.add_argument(
    "--output", required=True, help="Path to output directory, output.parquet"
)
args = parser.parse_args()

tmp_dir = os.getenv("SPARK_TMP_DIR", "/tmp")


# Initialize Spark session. Be warned: a lot of memory is needed for this task
spark = (
    SparkSession.builder.appName("GnomAD")
    .config("spark.driver.memory", "64g")
    .config("spark.executor.memory", "64g")
    .config("spark.local.dir", tmp_dir)
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
    .load(glob(args.input))
)


def analyze_allele_balance(histogram_string):
    """
    Analyze allele balance histogram to detect bias, especially when significantly lower than 0.5.
    """
    # Parse the histogram string
    if histogram_string is None:
        return (1.0, 0.5)  # No data, return no significant difference

    try:
        counts = [int(count) for count in histogram_string.split("|")]
        counts = np.array(counts, dtype=float)  # Use float instead of np.float64

        # Define bin centers (midpoints of each bin)
        bin_edges = np.linspace(0, 1, 21)
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

        # Calculate total number of observations
        total_observations = np.sum(counts)
        if total_observations == 0:
            return (1.0, 0.5)  # No data, return no significant difference

        # Calculate weighted mean
        weighted_mean = np.sum(bin_centers * counts) / total_observations

        # Calculate variance and standard error for t-test with protection against division by zero
        # Use formula for weighted variance
        variance = np.sum(counts * (bin_centers - weighted_mean) ** 2)
        if total_observations > 1:  # Avoid division by zero
            variance = variance / total_observations
        else:
            variance = 0.0

        # Add small epsilon to prevent division by zero
        std_error = np.sqrt(variance / max(total_observations, 1) + 1e-10)

        # Calculate t-statistic manually
        if std_error < 1e-8:  # Avoid very small denominators
            t_statistic = 0
            p_value = 1.0
        else:
            t_statistic = (weighted_mean - 0.5) / std_error
            # Approximate p-value using standard normal distribution
            p_value = 2 * (1 - stats.norm.cdf(abs(t_statistic)))

        # For specifically testing if the mean is lower than 0.5, we can use a one-sided test
        if weighted_mean < 0.5:
            p_value = p_value / 2  # Divide by 2 for one-sided test
        else:
            # If mean is >= 0.5, we're not interested in the lower tail
            p_value = 1 - (p_value / 2)

        # Convert numpy types to Python native types to avoid serialization issues
        return (float(p_value), float(weighted_mean))
    except Exception as e:
        # In case of any parsing errors, return default values
        return (1.0, 0.5)


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


# Now create a PySpark UDF that returns analysis results and a bias flag
def analyze_allele_balance_with_bias(histogram_string, p_threshold=0.05):
    if histogram_string is None:
        return (None, None, None)

    p_value, mean_balance = analyze_allele_balance(histogram_string)

    # Ensure all values are Python native types
    p_value = float(p_value) if p_value is not None else None
    mean_balance = float(mean_balance) if mean_balance is not None else None

    # Determine if the variant is biased (significantly different from 0.5 and mean < 0.5)
    is_biased = bool((p_value < p_threshold) and (mean_balance < 0.5))

    return (p_value, mean_balance, is_biased)


# Define the return schema for the UDF
result_schema = StructType(
    [
        StructField("p_value", DoubleType(), True),
        StructField("mean_balance", DoubleType(), True),
        StructField("is_biased", BooleanType(), True),
    ]
)

# Register the UDF
analyze_ab_udf = F.udf(analyze_allele_balance_with_bias, result_schema)

# Pattern matching for "0|0|0|0|..." sequences
ab_pattern = "^0(\\|0)*$"
age_pattern = "^0(\\|0)*$"


def process_dataframe(df, output_dir):
    df_with_spdi = (
        df.withColumn(
            "spdi", to_spdi_udf(F.col("chr"), F.col("pos"), F.col("ref"), F.col("alt"))
        )
        .withColumn("_seq", F.col("spdi").getItem("_seq"))
        .withColumn("_pos", F.col("spdi").getItem("_pos"))
        .withColumn("_del", F.col("spdi").getItem("_del"))
        .withColumn("_ins", F.col("spdi").getItem("_ins"))
        .drop("spdi")
    )
    del df
    df_with_analysis = (
        df_with_spdi.withColumn(  # if histogram is empty, set to null
            "ab_hist_alt_bin_freq",
            F.when(F.col("ab_hist_alt_bin_freq").rlike(ab_pattern), None).otherwise(
                F.col("ab_hist_alt_bin_freq")
            ),
        )
        .withColumn(  # if histogram is empty, set to null
            "age_hist_hom_bin_freq",
            F.when(F.col("age_hist_hom_bin_freq").rlike(age_pattern), None).otherwise(
                F.col("age_hist_hom_bin_freq")
            ),
        )
        .withColumn(  # if histogram is empty, set to null
            "age_hist_het_bin_freq",
            F.when(F.col("age_hist_het_bin_freq").rlike(age_pattern), None).otherwise(
                F.col("age_hist_het_bin_freq")
            ),
        )
        .withColumn("ab_analysis", analyze_ab_udf(F.col("ab_hist_alt_bin_freq")))
        .withColumn("ab_p_value", F.col("ab_analysis.p_value"))
        .withColumn("ab_mean", F.col("ab_analysis.mean_balance"))
        .drop("ab_analysis")
    )

    # optimize not to store non significant values for bias
    # Apply the conditions to set values to null
    df_with_bias_trimmed = df_with_analysis.withColumn(
        "ab_p_value",
        F.when((F.col("ab_mean") > 0.3) | (F.col("ab_p_value") > 0.05), None).otherwise(
            F.col("ab_p_value")
        ),
    ).withColumn(
        "ab_mean",
        F.when((F.col("ab_mean") > 0.3) | (F.col("ab_p_value") > 0.05), None).otherwise(
            F.col("ab_mean")
        ),
    )
    del df_with_analysis

    # Identify double columns
    double_cols = [
        field.name
        for field in df_with_bias_trimmed.schema.fields
        if field.dataType == DoubleType()
    ]

    # Cast double columns to float
    for col in double_cols:
        df_with_bias_trimmed = df_with_bias_trimmed.withColumn(
            col, F.col(col).cast(FloatType())
        )

    final_df = df_with_bias_trimmed.drop("chr", "pos", "ref", "alt").dropDuplicates(
        ["_seq", "_pos", "_del", "_ins"]
    )

    (
        final_df.repartition("_seq")
        .sortWithinPartitions("_seq", "_pos", "_del", "_ins")
        .write.option("compression", "zstd")
        .partitionBy("_seq")
        .parquet(output_dir)
    )


process_dataframe(df, args.output)

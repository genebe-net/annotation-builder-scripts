import pandas as pd
import genebe as gnb
import argparse

# Parse arguments
parser = argparse.ArgumentParser(description="Process data with pandas and genebe.")
parser.add_argument("--input", required=True, help="Path to input file, input.tsv.bz2")
parser.add_argument(
    "--output", required=True, help="Path to output directory, output.parquet"
)
args = parser.parse_args()


# Load the input file into a pandas DataFrame
df = pd.read_csv(args.input, sep="\t")

df.rename({"chrom": "chr"}, axis=1, inplace=True)

df_lifted = gnb.lift_over_variants_df(df, from_genome="hg19", dest_genome="hg38")
# replace chr_lifted with chr, and same for pos ref alt

# drop source columns chr pos ref alt

df_lifted.drop(["chr", "pos", "ref", "alt"], axis=1, inplace=True)
df_lifted.rename(
    columns={
        "chr_lifted": "chr",
        "pos_lifted": "pos",
        "ref_lifted": "ref",
        "alt_lifted": "alt",
    },
    inplace=True,
)
df_lifted.to_csv(args.output, sep="\t", index=False)

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
df = pd.read_csv(args.input, sep=",")

df.rename(
    {
        "Mutation": "variant",
        "Splicing effect": "effect",
        "Gene Symbol": "gene",
        "Entrez Gene ID": "entrezid",
    },
    axis=1,
    inplace=True,
)

df_parsed = gnb.parse_variants_df(df, genome="hg38")
# replace chr_lifted with chr, and same for pos ref alt

# drop source columns chr pos ref alt

df_ready = df_parsed[["chr", "pos", "ref", "alt", "effect", "gene", "entrezid"]]
df_ready.to_csv(args.output, sep="\t", index=False)

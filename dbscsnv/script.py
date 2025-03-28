import pandas as pd
import argparse

# Parse arguments
parser = argparse.ArgumentParser(description="Process data with pandas and genebe.")
parser.add_argument("--input", required=True, help="Path to input file, input.tsv")
parser.add_argument("--output_hg19", required=True, help="Path to output tsv file")
parser.add_argument("--output_hg38", required=True, help="Path to output tsv file")
args = parser.parse_args()


# Load the input file into a pandas DataFrame
df = pd.read_csv(args.input, sep="\t", na_values=".", low_memory=False)

# chr     pos     ref     alt     hg38_chr        hg38_pos   ada_score       rf_score
df = df[["chr", "pos", "ref", "alt", "hg38_chr", "hg38_pos", "ada_score", "rf_score"]]

df.rename({"chr": "hg19_chr", "pos": "hg19_pos"}, axis=1, inplace=True)

# Write result to TSV
df_hg19 = df[["hg19_chr", "hg19_pos", "ref", "alt", "ada_score", "rf_score"]].copy()
df_hg19.rename({"hg19_chr": "chr", "hg19_pos": "pos"}, axis=1, inplace=True)
df_hg19.dropna(inplace=True)

df_hg19.to_csv(args.output_hg19, sep="\t", index=False)


del df_hg19
df_hg38 = df[["hg38_chr", "hg38_pos", "ref", "alt", "ada_score", "rf_score"]].copy()
df_hg38.rename({"hg38_chr": "chr", "hg38_pos": "pos"}, axis=1, inplace=True)
df_hg38.dropna(inplace=True)
# convert pos to int
df_hg38["pos"] = df_hg38["pos"].astype(int)
df_hg38.to_csv(args.output_hg38, sep="\t", index=False)
del df_hg38

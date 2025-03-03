import pandas as pd
import argparse

parser = argparse.ArgumentParser(
    description="Process input data from mitomap. Convert gbfreq from prc to frac."
)
parser.add_argument("--input", required=True, help="Path to input file")
parser.add_argument("--output", required=True, help="Path to output file")
args = parser.parse_args()

# Read the TSV file
df = pd.read_csv(args.input, sep="\t")

# Divide the values in the 'gbfreq' column by 100 and create a new 'gbfreq_frac' column
df["gbfreq_frac"] = df["gbfreq"] / 100

# replace ref with value : with empty string
df["ref"] = df["ref"].str.replace(":", "")
df["alt"] = df["alt"].str.replace(":", "")


# Write the modified DataFrame back to a new TSV file
df.to_csv(args.output, sep="\t", index=False)

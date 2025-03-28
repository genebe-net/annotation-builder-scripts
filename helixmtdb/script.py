import pandas as pd
import argparse

# Parse arguments
parser = argparse.ArgumentParser(description="Process data with pandas and genebe.")
parser.add_argument("--input", required=True, help="Path to input file, input.tsv.bz2")
parser.add_argument("--output", required=True, help="Path to output tsv file")
args = parser.parse_args()


# Load the input file into a pandas DataFrame
df = pd.read_csv(args.input, sep="\t")

# Step 1: Create new column 'chr' with value 'M'
df["chr"] = "M"

# Step 2: Extract position from 'locus' and create 'pos' column
df["pos"] = df["locus"].str.split(":").str[1]

# Step 3: Extract 'ref' and 'alt' from 'alleles'
alleles = df["alleles"].apply(eval)
df["ref"] = alleles.str[0]
df["alt"] = alleles.str[1]

# Reorder columns: 'chr', 'pos', 'ref', 'alt' first, rest unchanged
columns_order = ["chr", "pos", "ref", "alt"] + [
    col for col in df.columns if col not in ["chr", "pos", "ref", "alt"]
]
df = df[columns_order]

df = df.drop(
    columns=[
        "locus",
        "alleles",
        "feature",
        "gene",
        "haplogroups_for_homoplasmic_variants",
        "haplogroups_for_heteroplasmic_variants",
        "mean_ARF",
        "max_ARF",
    ]
)

# Write result to TSV
df.to_csv(args.output, sep="\t", index=False)

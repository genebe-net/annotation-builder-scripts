#!/bin/bash

echo "Download data from https://public.boxcloud.com/d/1/b1!yMiLHRvDWU6q5KJlITj4Ogb-QiKsbnDfknk4Xn3Alr6RKPnGx5TtO-UL7Yi2pHBFgi0H_xtX5qcBv9MZFQmipcpOK1IetT7iq55ISrJWFLsvO98-diOae1LCIJ0KnLrAvLWcRJPMxCVb4rm1Cq2Wz9AGk0iCI4TslHOnxuwcd_-NKXbZkCuQc9FACxBOyEH0vY7SeU548Z2ZKD39cXKJECwuZWNzwE613EeGeL2PZ-r39lySi_ROvH5x0DR3AbqzRvqeB9o5F6TSX9gEa__8dmXLXjMR-MT82BIaFLfgmFXnUn4Wd17yeaUsW71gd2VtTLgoyQuSW9fTErHUSSfdm5FiHz-acdHjIGs3Ly23-BLGr2UqM45jD3YB0VlrGWixn_JhJ4T4_RFLC8cvFjyM3_iRVgvtf2Qtjne8fD58Lx3cQY7WAVpcEirhbxtr7rItnmdIMAp1jpl4-2Ck4p8uJEL0xi8dH-YPiVeer-jw8Dp9pq4oTvqYrTQX5j1RG_aHEi4p_uaVs6ty9oukCQ6-TpIeBUKu7_SSxjwTICYFfUcl9QlmN0MwXiyDC8QBI8ezrguP3JPBRifAYmDw1IU6yBA05CukAmraPcATL8CT_GIqeZEJ3Z22xipJ4pzhQXGuV4PzMzQh_BsOr_jGNQiTeYk1goXxRwoR7RghRvPs_YwqaST7EV4YDMjIBf0uVvzIHidnmyH02KDYK8HR71HW0XvmyXRw9Zm7GCNpEwyV2_ZlJ136eJ9zfGEpFu7BpPTknzBV7TLd__mJrP6tWwHNRVINnnzBX_hQ2-l-qvqRnJWLMohfYF44BiqEAI6jtTF4o07iT0HYDKED6tkR65GJhbD_Hrs7r-gzrztCdzkVrETkokgaD8g3M81OOcBXvDoYGTqYODg7U-hCsLF_g6CLcOwmwlm-O1CzglHujmFvFbQZXmPfBsvNVsqrU0TseJaJp1vX7p2fk1tPuRuxJQZ6qCH2QyQ7wdzX8mfN_zjeapk466mPk5vgg5ExxsvC-pLWKL_LwtS5SsCGQRaLs5o-MRmkZ7LXr-OTEsW3WMKSBPHtaqSN3bYyJJXgqEhofJTFIB8nEv115QSq8j4z3FgKVkPdhQAqrsOhW0b7XUvtDyjOgdcC1AJyNjD826FbymALExvBXpA0qK7UbnP_NFRsQTdhHFeQYCP8wllLmOa3SYzx3kW2XnsSx-yefxUNQogfhMuqMh_K5vrf5UMxjWCUnK_prbqoQj4qQ63aEqX9T8YUCFO1TAc7xXj8xL6F0S6md4hgSvNcoGItnQxGW97Kt3d9u3zHIZCj_GR6xujfj1JawfLhnjIur_Whiiyo5veNJvyqfK1PE28LBCMnAfGzlyMdWUIlK34kkp5wY0fyec_meeRaTRYSCm7TX5Y3xd5w9uUrTiSWIJ-e6LdVeG8FhPiUS-cK6b872Phet_eD0NUsZYf1gMSHpr1Zfj7TybfYI_Nxe4bx-Dna8UmEAfGs8E-sfjrgYfB8A69I4LLtrCqFddG0ibqB8z1TPcNdv7xiQlhH3f6q-29J2BCzmJnribD4rr-9/download"

set -e # fail if any fails

source ../_utils/download_genebe.sh

if [ ! -f input.zip ]; then
    wget 'https://public.boxcloud.com/d/1/b1!yMiLHRvDWU6q5KJlITj4Ogb-QiKsbnDfknk4Xn3Alr6RKPnGx5TtO-UL7Yi2pHBFgi0H_xtX5qcBv9MZFQmipcpOK1IetT7iq55ISrJWFLsvO98-diOae1LCIJ0KnLrAvLWcRJPMxCVb4rm1Cq2Wz9AGk0iCI4TslHOnxuwcd_-NKXbZkCuQc9FACxBOyEH0vY7SeU548Z2ZKD39cXKJECwuZWNzwE613EeGeL2PZ-r39lySi_ROvH5x0DR3AbqzRvqeB9o5F6TSX9gEa__8dmXLXjMR-MT82BIaFLfgmFXnUn4Wd17yeaUsW71gd2VtTLgoyQuSW9fTErHUSSfdm5FiHz-acdHjIGs3Ly23-BLGr2UqM45jD3YB0VlrGWixn_JhJ4T4_RFLC8cvFjyM3_iRVgvtf2Qtjne8fD58Lx3cQY7WAVpcEirhbxtr7rItnmdIMAp1jpl4-2Ck4p8uJEL0xi8dH-YPiVeer-jw8Dp9pq4oTvqYrTQX5j1RG_aHEi4p_uaVs6ty9oukCQ6-TpIeBUKu7_SSxjwTICYFfUcl9QlmN0MwXiyDC8QBI8ezrguP3JPBRifAYmDw1IU6yBA05CukAmraPcATL8CT_GIqeZEJ3Z22xipJ4pzhQXGuV4PzMzQh_BsOr_jGNQiTeYk1goXxRwoR7RghRvPs_YwqaST7EV4YDMjIBf0uVvzIHidnmyH02KDYK8HR71HW0XvmyXRw9Zm7GCNpEwyV2_ZlJ136eJ9zfGEpFu7BpPTknzBV7TLd__mJrP6tWwHNRVINnnzBX_hQ2-l-qvqRnJWLMohfYF44BiqEAI6jtTF4o07iT0HYDKED6tkR65GJhbD_Hrs7r-gzrztCdzkVrETkokgaD8g3M81OOcBXvDoYGTqYODg7U-hCsLF_g6CLcOwmwlm-O1CzglHujmFvFbQZXmPfBsvNVsqrU0TseJaJp1vX7p2fk1tPuRuxJQZ6qCH2QyQ7wdzX8mfN_zjeapk466mPk5vgg5ExxsvC-pLWKL_LwtS5SsCGQRaLs5o-MRmkZ7LXr-OTEsW3WMKSBPHtaqSN3bYyJJXgqEhofJTFIB8nEv115QSq8j4z3FgKVkPdhQAqrsOhW0b7XUvtDyjOgdcC1AJyNjD826FbymALExvBXpA0qK7UbnP_NFRsQTdhHFeQYCP8wllLmOa3SYzx3kW2XnsSx-yefxUNQogfhMuqMh_K5vrf5UMxjWCUnK_prbqoQj4qQ63aEqX9T8YUCFO1TAc7xXj8xL6F0S6md4hgSvNcoGItnQxGW97Kt3d9u3zHIZCj_GR6xujfj1JawfLhnjIur_Whiiyo5veNJvyqfK1PE28LBCMnAfGzlyMdWUIlK34kkp5wY0fyec_meeRaTRYSCm7TX5Y3xd5w9uUrTiSWIJ-e6LdVeG8FhPiUS-cK6b872Phet_eD0NUsZYf1gMSHpr1Zfj7TybfYI_Nxe4bx-Dna8UmEAfGs8E-sfjrgYfB8A69I4LLtrCqFddG0ibqB8z1TPcNdv7xiQlhH3f6q-29J2BCzmJnribD4rr-9/download' -O input.zip
    unzip input.zip
fi

if [ ! -f merged.tsv ]; then
    echo "Merge"
    cat dbscSNV1.1.chr1 | head -n1 > merged.tsv
    for chr in X Y {1..22}; do
        tail -n +2 dbscSNV1.1.chr$chr >> merged.tsv
    done
fi


# Directory for virtual environment
VENV_DIR=".venv"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $VENV_DIR

    # Activate virtual environment
    source $VENV_DIR/bin/activate

    # Install requirements
    echo "Installing requirements..."
    pip install -r requirements.txt
else
    source $VENV_DIR/bin/activate
fi

echo "I will call python script for further processing"
python script.py --input merged.tsv --output_hg19 ready_hg19.tsv --output_hg38 ready_hg38.tsv

# Deactivate virtual environment
deactivate



java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name dbscsnv-hg38 \
    --version 0.0.1-1.1 \
    --title "dbscSNV1.1 hg38" \
    --has-header true \
    --input ready_hg38.tsv \
    --species homo_sapiens \
    --genome GRCh38 \
    --force

java -jar $GENEBE_CLIENT_JAR  annotation create-from-tsv \
    --owner @genebe \
    --name dbscsnv-hg19 \
    --version 0.0.1-1.1 \
    --title "dbscSNV1.1 hg19" \
    --has-header true \
    --input ready_hg19.tsv \
    --species homo_sapiens \
    --genome GRCh37 \
    --force

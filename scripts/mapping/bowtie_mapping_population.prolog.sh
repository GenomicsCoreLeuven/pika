GENOME_DIR="";

cd $VSC_SCRATCH_NODE;
mkdir genome;
cd genome;
rsync -ahr $GENOME_DIR/* .;


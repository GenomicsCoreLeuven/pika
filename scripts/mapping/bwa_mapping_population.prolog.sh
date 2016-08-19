GENOME_DIR="";
GENOME_DIR="$GENOME_DIR/bwa/0.7.12";

cd $VSC_SCRATCH_NODE;
mkdir genome;
cd genome;
rsync -ahr $GENOME_DIR/* .;


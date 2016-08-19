GENOME_DIR="";
GENOME_DIR="$GENOME_DIR/bowtie2/2.2.4/";
cd $VSC_SCRATCH_NODE;
mkdir genome;
cd genome;
rsync -ahr $GENOME_DIR/* .;


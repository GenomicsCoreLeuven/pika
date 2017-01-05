#extra_modules

module load STAR;

GENOME_DIR="";
THREADS=1;
ENSEMBL="current";
SCRATCH_DIR=~;

JOBID="";
mkdir -p $SCRATCH_DIR/$JOBID/genome;

MY_TMP_DIR="$SCRATCH_DIR/$JOBID/genome";
cd $MY_TMP_DIR;
rsync -ahr $GENOME_DIR/genome.fa .;
rsync -ahr $GENOME_DIR/Ensembl/$ENSEMBL/genes.gtf .;

STAR --runThreadN $THREADS --runMode genomeGenerate --genomeDir $MY_TMP_DIR --genomeFastaFiles $MY_TMP_DIR/genome.fa --sjdbGTFfile $MY_TMP_DIR/genes.gtf;

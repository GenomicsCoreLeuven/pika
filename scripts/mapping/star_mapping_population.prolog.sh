GENOME_DIR="";
THREADS=1;
ENSEMBL="current";
SCRATCH_DIR=~;

cd $SCRATCH_DIR;
mkdir tmp.$PBS_JOBID;
MY_TMP_DIR="$SCRATCH_DIR/tmp.$PBS_JOBID";
cd tmp.$PBS_JOBID;
rsync -ahr $GENOME_DIR/genome.fa .;
rsync -ahr $GENOME_DIR/Ensembl/$ENSEMBL/genes.gtf .;

module use /staging/leuven/stg_00019/software/modulefiles;
module load STAR/2.5.2b-GCC_4.9.2;

STAR --runThreadN $THREADS --runMode genomeGenerate --genomeDir $MY_TMP_DIR --genomeFastaFiles $MY_TMP_DIR/genome.fa --sjdbGTFfile $MY_TMP_DIR/genes.gtf;

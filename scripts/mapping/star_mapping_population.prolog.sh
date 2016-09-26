GENOME_DIR="";
THREADS=1;
ENSEMBL="current";

cd $VSC_SCRATCH;
mkdir tmp.$PBS_JOBID;
cd tmp.$PBS_JOBID;
rsync -ahr $GENOME_DIR/genome.fa .;
rsync -ahr $GENOME_DIR/Ensembl/$ENSEMBL/genes.gtf .;

module use /staging/leuven/stg_00019/software/modulefiles;
module load STAR/2.5.2b-GCC_4.9.2;

STAR --runThreadN $THREADS --runMode genomeGenerate --genomeDir $VSC_SCRATCH/tmp.$PBS_JOBID --genomeFastaFiles $VSC_SCRATCH/tmp.$PBS_JOBID/genome.fa --sjdbGTFfile $VSC_SCRATCH/tmp.$PBS_JOBID/genes.gtf;

module load vcflib/20160720-intel-2015a

PROJECT_DIR="";
VCF_DIR="$PROJECT_DIR/parts";
OUTPUT_DIR="$PROJECT_DIR/";
FREEBAYES_OUTPUT_FILE_NAME="freebayes.m15.q15.useduplicates.ploidy2.vcf";
SCRATCH_DIR="$VSC_SCRATCH_NODE";

cd $VCF_DIR;
cat *.vcf | vcffirstheader > $SCRATCH_DIR/combined.tmp
grep "^#" $SCRATCH_DIR/combined.tmp > $SCRATCH_DIR/sorted.tmp;
grep -v "^#" $SCRATCH_DIR/combined.tmp | sort -k1,1 -k2,2n >> $SCRATCH_DIR/sorted.tmp;
rm $SCRATCH_DIR/combined.tmp;
cat $SCRATCH_DIR/sorted.tmp | vcfuniq > $OUTPUT_DIR/$FREEBAYES_OUTPUT_FILE_NAME;



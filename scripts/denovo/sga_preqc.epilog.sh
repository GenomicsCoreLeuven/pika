#extra_modules
module load SGA

PROJECT_DIR="";
OUTPUT_DIR="$PROJECT_DIR/sga_preqc";

sga-preqc-report.py $OUTPUT_DIR/*.preqc;

#compare to the sga standard examples
sga-preqc-report.py -o standard_examples $OUTPUT_DIR/*.preqc /staging/leuven/stg_00019/genome/sga_preqc_examples/*.preqc;

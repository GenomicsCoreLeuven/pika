# pika

[![DOI](https://zenodo.org/badge/23912/GenomicsCoreLeuven/pika.svg)](https://zenodo.org/badge/latestdoi/23912/GenomicsCoreLeuven/pika) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

pika is the *Pipeline Integration Kit for hpc Analysis*. 
pika is originally aimed to create bioinformatics pipelines from pbs scripts. This for an easy hpc usage for Biological researchers. However the implementation of pika is completely independent from it's pipelines, scripts, modules and grid engine. Resulting in a tool available for any research field on any computer or cluster.

##Usage
The main script is found in the source directory. Just execute the pika.sh file (best is to make an alias, including the complete path to the script (use bash as execution, not sh)). First execution will ask some configuration parameters (pika change config). Some standard pipelines and scripts are already included. pika should work out of the box on the [vsc](https://www.vscentrum.be/). If used on other hpc systems, probably the modules will have to change (these can be found in the modules directory).   


#Download
The code of pika is found in the source directory. All scripts/jobs (pbs) are found in the scripts directory, divided into subfolders according to type. All pipelines are summed into the pipeline directory. The script uses this structure, but when a script or pipeline is added (as a file), it is added in the tool.
###Release Download
The releases can be downloaded in the release tab or with by clicking on the download button. Just unpack the download, and the tool is ready to use.
###Git clone
On the vsc, you need to switch to the latest toolchain (source switch_to_2015a):
```bash
module load git
git clone https://github.com/GenomicsCoreLeuven/pika.git
#when the clone is ready, the executable is found in source/pike.sh

#to update your current version use:
module load git
git pull
```

# Contact
[Genomics Core](http://www.genomicscore.be "Genomics Core website")  
Center for Human Genetics  
UZ – KU Leuven  
Herestraat 49 PO box 602  
B-3000 Leuven, Belgium  

Mail: [koen.herten@kuleuven.be](mailto:koen.herten@kuleuven.be "")

#License
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0) This work is licensed under GPL v3. A copy of the license is included

#Citing

Koen Herten. (2016). pika: pika 16.08. Zenodo. 10.5281/zenodo.60342

[![DOI](https://zenodo.org/badge/23912/GenomicsCoreLeuven/pika.svg)](https://zenodo.org/badge/latestdoi/23912/GenomicsCoreLeuven/pika)


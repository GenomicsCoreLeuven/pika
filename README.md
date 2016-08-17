# pika

[![DOI](https://zenodo.org/badge/23912/GenomicsCoreLeuven/pika.svg)](https://zenodo.org/badge/latestdoi/23912/GenomicsCoreLeuven/pika) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

pika is the *Pipeline Integration Kit for hpc Analysis*. 
pika, named after the *Ochotona* species, is originally aimed to create bioinformatics pipelines from pbs scripts. This for an easy hpc usage for Biological researchers. However the implementation of pika is completely independent from it's pipelines and scripts. Resulting in a tool available for any research field.

##Usage
The main script is found in the source directory. Just execute the pika.sh file. First execution will ask some configuration parameters. Some standard pipelines and scripts are already included. pika should work out of the box on the [vsc](https://www.vscentrum.be/). If used on other hpc systems, probably the modules will have to change (these modules are always listed at the top).   


##Download
The code of pika is found in the source directory. All scripts/jobs (pbs) are found in the scripts directory, divided into subfolders according to type. All pipelines are summed into the pipeline directory. The script uses this structure, but when a script or pipeline is added (as a file), it is added in the tool.

## Contact
[Genomics Core](http://www.genomicscore.be "Genomics Core website")  
Center for Human Genetics  
UZ – KU Leuven  
Herestraat 49 PO box 602  
B-3000 Leuven, Belgium  

Mail: [koen.herten@kuleuven.be](mailto:koen.herten@kuleuven.be "")

##Licence
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

##Citing
[![DOI](https://zenodo.org/badge/23912/GenomicsCoreLeuven/pika.svg)](https://zenodo.org/badge/latestdoi/23912/GenomicsCoreLeuven/pika)


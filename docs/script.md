# Script
Each script is an adjusted sh/bash script with a fixed layout. The layout can be split into different blocks:
1. RUN
2. VERSION
3. HELP
4. HOWTO
5. OPTIONS
6. MODULES
7. PARAMETERS
8. BATCH PARAMETERS
9. SCRIPT

# RUN
The run block defines the parameters needed for the grid engine, like walltime, needed nodes, needed memory, etc.
# VERSION
The version of the script
# HELP
This is a help part of the script. The help lines will be shown when the user asks for the help of the script (pika job help [jobname])
# HOWTO
This part of the script helps with the execution. It tells the user if files need to be prepared, and how. These lines will be shown when the user asks for the howto (pika job howto [jobname]) and in the pipeline file.
# OPTIONS
Options for scripts can be defined in this block. A line discribes the option name, if it is mandatory or optional, and the replacement of this option. This replacement is a sed command where the word value will be replaced with the given value on the command line. To change an option, the name of the option equals the value (with spaces in double quotes) is used.
# MODULES
#extra_modules
This line will be replaced by the extra modules line of the configuration file. These are usually to add new module sources, to purge modules, etc
Module load
This part is to load the tools. Only the name of tool has to be added. The correct version will be found in the modules directory. The to use versions can be configured, or be adjusted by a parameter.
# PARAMETERS
All parameters in the script should be combined at the top for readability. These parameters include the project directory (is automatically set by the script), the input and output directory, genome directory (is set by an variable, usually mandatory), etc.
#batch parameters
This line will be adjusted if a batch is submitted (see submission).
# SCRIPT
Creation of the temporary directory
A temporary directory will be created in the scratch directory, using the job id, and a random generated name (helpfull for batch execution).
The actual script
This is the location that is free for the user to implement the script for the tool.
Copy the content of the temporary directory (the output of the tool) to the output directory.


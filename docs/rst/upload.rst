Instructions for uploading data to the server
=============================================

Before running the pipeline, first upload the input file to the server as follows:

Press on the "choose files" button, and select the root folder of the files

Uploading folder of fastq files
-------------------------------

* Fastq files must be organized, within the selected folder (root folder), into subfolders as shown below. Subfolders names are derived from sample names.
* Each subfolder contains the relevant fastq file, which can be compressed into the "gz" format.
* Fastq file names must end with "_R1.fastq(.gz)" or "_R1.fq(.gz)" for single-read data. The "R" prefix denotes the read number.
* In the case of paired-end data (required for Mars-Seq), corresponding files must exist, with suffix "_R2.fastq(.gz)" instead of "_R1.fastq(.gz)".

**For example:**

* root folder
    - sample1
        * sample1_R1.fastq
        * sample1_R2.fastq (must exist in Mars-seq and in paired-end)
    - sample2
        * sample2_R1.fastq
        * sample2_R2.fastq (must exist in Mars-seq and in paired-end)


The pipeline also supports the old convention of the fastq file names *_L00*_R1_0*.fastq. The letter "L" denotes the lane number, "R" denotes the read number, and the numbers 001,002 etc denote serial number of the file for each lane and read

**For example:**

* root folder
    - sample1
        * sample1_S0_L001_R1_001.fastq
        * sample1_S0_L001_R1_002.fastq
        * sample1_S0_L002_R1_001.fastq
        * sample1_S0_L002_R1_002.fastq
        * sample1_S0_L001_R2_001.fastq
        * sample1_S0_L001_R2_002.fastq
        * sample1_S0_L002_R2_001.fastq
        * sample1_S0_L002_R2_002.fastq
    - sample2
        * ...

Uploading input for the demultiplexing pipeline
-----------------------------------------------

* For the pipeline of demultiplexing from BCL files: upload the original bcl folder. The original folder name should adhere to the template: <date>_<field2>.<field3>_field4>, e.g. 180514_NB551168_0123_AHTHHKBGX5.
* For the pipeline of demultiplexing from FASTQ files: upload the folder containing the undetermined FASTQ files. Note: the pipeline can process multiple files per read as input (e.g., multiple files for each *R1* and *R2*, such as undetermined_fastq_files/Undetermined_S0_L001_R1_001.fastq.gz and Undetermined_S0_L002_R1_001.fastq.gz).

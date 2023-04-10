Run Demultiplexing pipeline
###########################

There are 2 pipelines for demultiplexing; the first accepts BCL files as input, the second fastq files.

Demultiplexing from BCL files
-----------------------------

Upload BCL files to the server according to the following instructions:

.. toctree::
    :maxdepth: 1

    upload

All original BCL file folders must be built according to Next-seq (or Hi-seq) machine requirements. Folder names should adhere to the template <date>_<machine name>_<run number>_<flowcell id>, e.g.  "170802_NB501465_0140_AH3W3KBGX3".

The pipeline converts bcl files to fastq files, and demultiplexes fastq files according to MAR-seq or True-seq (or semi- True-seq) protocols.


Demultiplexing from fastq files
-------------------------------

The pipeline demultiplexes fastq files according to MAR-seq or True-seq (or semi- True-seq) protocols.

Upload fastq files to the server according to the following instructions:

.. toctree::
    :maxdepth: 1

    upload


Note that the pipeline get as input one file per read (i.e. one file for each of *R1*, *R2*, *I1* etc.).
Choose the root folder of the fastq files from the list.

If the sequencing is single read, choose the file with *R1* in its file name for read 1, the file with either *R2* or *I1* for index read, and leave the read 2 field empty.

If the sequencing is paired end, choose the file with *R1* in its file name for read 1, the file with *R2* for read 2, and the file with *I1* for index read. If no file name includes *I1*, choose one with *R2* for index read, and one with *R3* for read 2.

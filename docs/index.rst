.. _manual-main:

UTAP2: User-friendly Transcriptome and Epigenome Analysis Pipeline
===================================================

NGS technology is routinely used to characterize the genome and detect gene expression differences among cell types, genotypes and conditions. Advances in short-read sequencing instruments such as Illumina Next-Seq, have yielded easy-to-operate machines, with higher throughput, at a lower price per base. However, processing this data requires bioinformatics expertise to tailor and execute specific solutions for each type of library preparation.

In order to enable fast and user-friendly transcriptome and epigenome NGS sequence data analysis, we developed an intuitive and scalable pipeline that executes the full process. Transcriptome analysis starts from cDNA sequences derived from RNA (for the protocols: TruSeq, bulk MARS-Seq, Ribo-Seq and SCRB-Seq) and ends with gene count and/or differentially expressed genes. Output files are organized in structured folders, and results summaries are provided in rich and comprehensive reports, containing dozens of plots, tables and links. In addition, the pipeline supports epigenome sequence analysis for ChIP-Seq and ATAC-Seq, including alignment and peak detection. 

Our User-friendly Transcriptome Analysis Pipeline (UTAP) can be easily installed through a single singularity image that includes all the necessary software and files inside miniconda environment required for running Snakemake  workflows and taking advantage of parallel cluster resources.

UTAP is a web-based intuitive platform currently installed on Weizmann institute’s cluster and is used extensively by the institute researches. It is also available as an open-source application for the biomedical research community, thus enabling researchers with limited programming skills, to efficiently and accurately analyse transcriptome and epigenome sequence data. 



.. toctree::
    :maxdepth: 2

 
    rst/rna-mars-seq-results
    rst/atac-seq-results
    rst/chip-seq-results
    rst/ribo-seq-results
    rst/installation
    rst/user-guide
    rst/releases
    rst/source-code
    rst/demo-site

License
=======
UTAP is licensed under GNU General Public License version 3. License needed for commercial use.


Author
======

UTAP team

support:
utap@weizmann.ac.il

Bioinformatics unit at Life Sciences Core Facilities (LSCF)

Weizmann Institute of Science, Rehovot 76100, Israel.

Acknowlegments
==============

Please cite: Kohen R, Barlev J, Hornung G, Stelzer G, Feldmesser E, Kogan K, Safran M, Leshkowitz D: UTAP: User-friendly Transcriptome Analysis Pipeline. BMC Bioinformatics 2019, 20(1):154.

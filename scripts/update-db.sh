

while getopts a:b:c:d:e:f: option
do
 case "${option}"
 in
   a) export HOST_MOUNT=${OPTARG};; # Mount point from the docker on the host. For example: /home/labs/bioservices/pmrefael/docker_test
   b) export REPLY_EMAIL=${OPTARG};; # Users can reply to this email. For example: bioinfo@weizmann.ac.il
   c) export ADMIN_PASS=${OPTARG};; # Admin password (superuser of django)
   d) export TEST=${OPTARG};; # 1 or None - cause to create toy genome in the database
   e) export INTERNAL_USERS=${OPTARG};; # 1 or None  - The system works with ldap and Collaboration folders of Weizmann.
   f) export GENOMES_DIR=${OPTARG};;#For INTERNAL_USERS only: full path to cellranger genomes directory or None
   \?) echo "Invalid option: -$OPTARG" >&2;;
 esac
done


printf "Input variables in update-db.sh:\n=====================================\nHOST_MOUNT: $HOST_MOUNT\nREPLY_EMAIL: $REPLY_EMAIL\nADMIN_PASS: $ADMIN_PASS\nTEST: $TEST\nINTERNAL_USERS: $INTERNAL_USERS\nGENOMES_DIR: $GENOMES_DIR\n\n==============\n"

echo "Start build database of Djnago"
/opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py makemigrations analysis
/opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py migrate

if [ $INTERNAL_USERS = "None" ]; then # if not empty variable - it is NOT internal users

  echo "from analysis.models import CustomUser; CustomUser.objects.create_superuser('admin', '$REPLY_EMAIL', '$ADMIN_PASS')" |  /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell


  # Update DB with the genomes and annotations:

  # Remove old genomes and annotations:
  declare -a genomes_db=("StarGenome","StarAnnotation","CellRangerGenome","Bowtie2Genome","TssFile","AllGenomes","ChromosomeInfo","Bowtie1Rrna","InterMine")
  for i in "${genomes_db[@]}"
  do
    echo "from analysis.models import $i; \
    $i.objects.all().delete()" \
    | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
    
    #The names must be in lower case characters
#    echo "UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='analysis_${i,,};'" | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py dbshell
  done
  
  #declare -a genomes=("homo_sapiens" "StarAnnotation","mouse","zebra_fish")
  declare -a genomes_path_star="$GENOMES_DIR/star"
  declare -a genomes_path_bowtie2="$GENOMES_DIR/bowtie2"
  declare -a genomes_path_bowtie1_rRNA="$GENOMES_DIR/bowtie1_rRNA"
  declare -a chromosomes_sizes="$GENOMES_DIR/chromosomes_sizes"
  declare -a tss_files="$GENOMES_DIR/tss_files"
  
  if [ -d "$genomes_path_star/homo_sapiens" ]; then
    echo "from analysis.models import StarGenome; \
    sh=StarGenome(creature=\"Homo_sapiens\", alias=\"hg38\", version=38.0, source=\"iGenomes\", path=\"$genomes_path_star/homo_sapiens/hg38/star_index/\"); \
    sh.save(); \
    from analysis.models import StarAnnotation; \
    StarAnnotation(genome=sh,creature=\"Homo_sapiens\", alias=\"Refseq\", version=38.0, source=\"refGene\", path=\"$genomes_path_star/homo_sapiens/hg38/annotation/refseq/hg38.genes.gtf\", path3p=\"$genomes_path_star/hg38/annotation/refseq/hg38.genes.3utr.gtf\", path_UTR_CDS=\"$genomes_path_star/homo_sapiens/hg38/annotation/cds_utr_without_overlap/hg38_cds_UTR_without_overlap.gtf\").save(); \
    StarAnnotation(genome=sh,creature=\"Homo_sapiens\", alias=\"genecode\", version=38.0, source=\"genecode\", path=\"$genomes_path_star/homo_sapiens/hg38/annotation/gencode/hg38-gencode.genes.gtf\", path3p=\"$genomes_path_star/hg38/annotation/gencode/hg38-gencode.genes.3utr.gtf\").save(); \
    from analysis.models import Bowtie2Genome; \
    bh=Bowtie2Genome(creature=\"Homo_sapiens\", alias=\"hg38\", version=38.0, source=\"iGenomes\", path=\"$genomes_path_bowtie2/homo_sapiens/hg38/bowtie2_index/genome\", fasta=\"$genomes_path_bowtie2/homo_sapiens/hg38/fasta/genome.fa\"); \
    bh.save(); \
    from analysis.models import Bowtie1Rrna; \
    b1h=Bowtie1Rrna(creature=\"Homo_sapiens\", alias=\"hg38\",path=\"$genomes_path_bowtie1_rRNA/homo_sapiens/hg38/bowtie1_rRNA_index/rRNA\", fasta=\"$genomes_path_bowtie1_rRNA/homo_sapiens/hg38/fasta/rRNA_hg38.fasta\"); \
    b1h.save(); \
    from analysis.models import ChromosomeInfo; \
    ch=ChromosomeInfo(genome=bh, creature=\"Homo_sapiens\", alias=\"hg38\", path=\"$chromosomes_sizes/homo_sapiens/hg38/hg38.chrom.sizes\"); \
    ch.save(); \
    from analysis.models import AllGenomes; \
    ah=AllGenomes(creature=\"Homo_sapiens\", alias=\"hg38\", star_genome=sh, bowtie2_genome=bh, bowtie1_rRNA=b1h, chromosomes_sizes=ch); \
    ah.save()" \ | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell 
  fi
  
  
  if [ -d "$genomes_path_star/mouse" ]; then
    echo "from analysis.models import StarGenome; \
    sm=StarGenome(creature=\"Mus_musculus\", alias=\"mm10\", version=10.0, source=\"iGenomes\", path=\"$genomes_path_star/mouse/mm10/star_index/\"); \
    sm.save(); \
    from analysis.models import StarAnnotation; \
    StarAnnotation(genome=sm,creature=\"Mus_musculus\", alias=\"Refseq\", version=10.0, source=\"iGenomes\", path=\"$genomes_path_star/mouse/mm10/annotation/refseq/mm10.genes.gtf\", path3p=\"$genomes_path_star/mouse/mm10/annotation/refseq/mm10.genes.3utr.gtf\").save(); \
    StarAnnotation(genome=sm,creature=\"Mus_musculus\", alias=\"gencode\", version=10.0, source=\"gencode\", path=\"$genomes_path_star/mouse/mm10/annotation/gencode/mm10-gencode.genes.gtf\", path3p=\"$genomes_path_star/mouse/mm10/annotation/gencode/mm10-gencode.genes.3utr.gtf\").save()" \
    | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
    
    #Bowtie2 index: - change the names:
    echo "from analysis.models import Bowtie2Genome; \
    bm=Bowtie2Genome(creature=\"Mus_musculus\", alias=\"mm10\", version=10.0, source=\"iGenomes\", path=\"$genomes_path_bowtie2/mouse/mm10/bowtie2_index/mm10\", fasta=\"$genomes_path_bowtie2/mouse/mm10/fasta/genome.fa\"); \
    bm.save(); \
    from analysis.models import TssFile; \
    TssFile(genome=bm, creature=\"Mus_musculus\", alias=\"+-2500\", version=10.0, source=\"gencode\",path=\"$tss_files/mouse/mm10/mm10.TSS_+2500_-2500_uniqueProm.bed\").save(); \
    from analysis.models import TssFile; \
    TssFile(genome=bm, creature=\"Mus_musculus\", alias=\"+-500\", version=10.0, source=\"gencode\",path=\"$tss_files/mouse/mm10/mm10.TSS_+500_-500_uniqueProm.bed\").save(); \
    from analysis.models import ChromosomeInfo; \
    cm=ChromosomeInfo(genome=bm, creature=\"Mus_musculus\", alias=\"mm10\", path=\"$chromosomes_sizes/mouse/mm10/mm10.chrom.sizes\"); \
    cm.save()" \ | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
    fi


    if [ -d "$genomes_path_star/zebra_fish" ]; then
    echo "from analysis.models import StarGenome; \
    g=StarGenome(creature=\"Danio_rerio\", alias=\"danRer11\", version=11.0, source=\"iGenomes\", path=\"$genomes_path_star/zebra_fish/danRer11/star_index/\"); \
    g.save(); \
    from analysis.models import StarAnnotation; \
    StarAnnotation(genome=g,creature=\"Danio_rerio\", alias=\"iGenomes-Refseq\", version=10.0, source=\"iGenomes-Refseq\", path=\"$genomes_path_star/zebra_fish/danRer11/zebra_fish/danRer11/annotation/refseq/danRer11.genes.gtf\", path3p=\"$genomes_path_star/zebra_fish/danRer11/zebra_fish/danRer11/annotation/refseq/danRer11.genes.3utr.gtf\").save()" \
    | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
    fi
fi
    
#  echo "from analysis.models import StarGenome; \
#  StarGenome.objects.all().delete()"  \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import StarAnnotation; \
#  StarAnnotation.objects.all().delete()"  \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import CellRangerGenome; \
#  CellRangerGenome.objects.all().delete()"  \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import Bowtie2Genome; \
#  Bowtie2Genome.objects.all().delete()"  \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import TssFile; \
#  TssFile.objects.all().delete()"  \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  #The names must be in lower case characters
#  echo "UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='analysis_stargenome';" | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py dbshell
#  echo "UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='analysis_starannotation';" | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py dbshell
#  echo "UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='analysis_cellrangergenome';" | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py dbshell
#  echo "UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='analysis_bowtie2genome';" | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py dbshell
#  echo "UPDATE SQLITE_SEQUENCE SET SEQ=0 WHERE NAME='analysis_tssfile';" | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py dbshell
#
#  if [ $TEST != "None" ]; then # Not empty variable
#    echo "from analysis.models import StarGenome; \
#    g=StarGenome(creature=\"toy\", alias=\"toy\", version=1.0, source=\"toy\", path=\"$HOST_MOUNT/utap-meta-data/genomes/toy/toy/toy/STAR_index/\"); \
#    g.save(); \
#    from analysis.models import StarAnnotation; \
#    StarAnnotation(genome=g,creature=\"toy\", alias=\"toy\", version=1.0, source=\"toy\", path=\"$HOST_MOUNT/utap-meta-data/genomes/toy/toy/toy/toy.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/toy/toy/toy/toy.genes.3utr.gtf\").save()" \
#    | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#
#    echo "from analysis.models import Bowtie2Genome; \
#    g=Bowtie2Genome(creature=\"toy\", alias=\"toy\", version=1.0, source=\"toy\", path=\"$HOST_MOUNT/utap-meta-data/genomes/toy/toy/toy/BOWTIE2_index/toy\"); \
#    g.save(); \
#    from analysis.models import TssFile; \
#    TssFile(genome=g,creature=\"toy\", alias=\"toy\", version=1.0, source=\"toy\", path=\"$HOST_MOUNT/utap-meta-data/genomes/toy/toy/toy/toy.tss.bed\").save()" \
#    | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#  fi
#
#
#  echo "from analysis.models import StarGenome; \
#  g=StarGenome(creature=\"Homo_sapiens\", alias=\"hg19\", version=19.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/STAR_index/\"); \
#  g.save(); \
#  from analysis.models import StarAnnotation; \
#  StarAnnotation(genome=g,creature=\"Homo_sapiens\", alias=\"iGenomes-Refseq\", version=19.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/hg19.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/hg19.genes.3utr.gtf\").save(); \
#  StarAnnotation(genome=g,creature=\"Homo_sapiens\", alias=\"Gencode\", version=19.0, source=\"Gencode\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/hg19-genecode.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/hg19-genecode.genes.3utr.gtf\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import StarGenome; \
#  g=StarGenome(creature=\"Homo_sapiens\", alias=\"hg38\", version=38.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/STAR_index/\"); \
#  g.save(); \
#  from analysis.models import StarAnnotation; \
#  StarAnnotation(genome=g,creature=\"Homo_sapiens\", alias=\"iGenomes-Refseq\", version=38.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/hg38.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/hg38.genes.3utr.gtf\").save(); \
#  StarAnnotation(genome=g,creature=\"Homo_sapiens\", alias=\"Gencode\", version=38.0, source=\"Gencode\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/hg38-gencode.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/hg38-gencode.genes.3utr.gtf\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import StarGenome; \
#  g=StarGenome(creature=\"Mus_musculus\", alias=\"mm10\", version=10.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/STAR_index/\"); \
#  g.save(); \
#  from analysis.models import StarAnnotation; \
#  StarAnnotation(genome=g,creature=\"Mus_musculus\", alias=\"iGenomes-Refseq\", version=10.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/mm10.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/mm10.genes.3utr.gtf\").save(); \
#  StarAnnotation(genome=g,creature=\"Mus_musculus\", alias=\"Gencode\", version=10.0, source=\"Gencode\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/mm10-gencode.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/mm10-gencode.genes.3utr.gtf\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import StarGenome; \
#  g=StarGenome(creature=\"Danio_rerio\", alias=\"danRer10\", version=10.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Danio_rerio/UCSC/danRer10/STAR_index/\"); \
#  g.save(); \
#  from analysis.models import StarAnnotation; \
#  StarAnnotation(genome=g,creature=\"Danio_rerio\", alias=\"iGenomes-Refseq\", version=10.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Danio_rerio/UCSC/danRer10/danRer10.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Danio_rerio/UCSC/danRer10/danRer10.genes.3utr.gtf\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import StarGenome; \
#  g=StarGenome(creature=\"Solanum_lycopersicum\", alias=\"sl3\", version=3.0, source=\"SGN\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Solanum_lycopersicum/SGN/sl3/STAR_index/\"); \
#  g.save(); \
#  from analysis.models import StarAnnotation; \
#  StarAnnotation(genome=g,creature=\"Solanum_lycopersicum\", alias=\"SGN\", version=3.0, source=\"SGN\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Solanum_lycopersicum/SGN/sl3/sl3.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Solanum_lycopersicum/SGN/sl3/sl3.genes.3utr.gtf\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import StarGenome; \
#  g=StarGenome(creature=\"Arabidopsis_thaliana\", alias=\"tair10\", version=10.0, source=\"iGenomes-NCBI\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/NCBI/tair10/STAR_index/\"); \
#  g.save(); \
#  from analysis.models import StarAnnotation; \
#  StarAnnotation(genome=g,creature=\"Arabidopsis_thaliana\", alias=\"iGenomes-NCBI\", version=10.0, source=\"iGenomes-NCBI\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/NCBI/tair10/tair10.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/NCBI/tair10/tair10.genes.3utr.gtf\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import StarGenome; \
#  g=StarGenome(creature=\"Arabidopsis_thaliana\", alias=\"tair11-araport\", version=11.0, source=\"ARAPORT\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/ARAPORT/tair11/STAR_index/\"); \
#  g.save(); \
#  from analysis.models import StarAnnotation; \
#  StarAnnotation(genome=g,creature=\"Arabidopsis_thaliana\", alias=\"araport\", version=11.0, source=\"ARAPORT\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/ARAPORT/tair11/tair11-araport.genes.gtf\", path3p=\"$HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/ARAPORT/tair11/tair11-araport.genes.3utr.gtf\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#
#  #Bowtie2 index: - change the names:
#  echo "from analysis.models import Bowtie2Genome; \
#  g=Bowtie2Genome(creature=\"Homo_sapiens\", alias=\"hg38\", version=38.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/BOWTIE2_index/hg38\"); \
#  g.save(); \
#  from analysis.models import TssFile; \
#  TssFile(genome=g,creature=\"Homo_sapiens\", alias=\"None\", version=38.0, source=\"Gencode\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/hg38..TSS_+2500_-2500_uniqueProm.bed\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import Bowtie2Genome; \
#  g=Bowtie2Genome(creature=\"Homo_sapiens\", alias=\"hg19\", version=19.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/BOWTIE2_index/hg19\"); \
#  g.save(); \
#  from analysis.models import TssFile; \
#  TssFile(genome=g,creature=\"Homo_sapiens\", alias=\"None\", version=19.0, source=\"Gencode\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/hg19.TSS_+2500_-2500_uniqueProm.bed\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import Bowtie2Genome; \
#  g=Bowtie2Genome(creature=\"Mus_musculus\", alias=\"mm10\", version=10.0, source=\"iGenomes-Refseq\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/BOWTIE2_index/mm10\"); \
#  g.save(); \
#  from analysis.models import TssFile; \
#  TssFile(genome=g,creature=\"Mus_musculus\", alias=\"+-500\", version=10.0, source=\"Gencode\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/mm10.TSS_+500_-500_uniqueProm.bed\").save(); \
#  TssFile(genome=g,creature=\"Mus_musculus\", alias=\"+-2500\", version=10.0, source=\"Gencode\", path=\"$HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/mm10.TSS_+2500_-2500_uniqueProm.bed\").save()" \
#  | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#fi

#if [ $INTERNAL_USERS != "None" ]; then # if not empty variable - it is internal users
#
#
#  echo "from analysis.models import CellRangerGenome; \
#g=CellRangerGenome(creature=\"ERCC\", alias=\"ercc92\", version=\"1.2.0\", path=\"$GENOMES_DIR/genomes/cellranger-3.0.0/refdata-cellranger-ercc92-1.2.0\"); \
#g.save()" \
#| /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import CellRangerGenome; \
#g=CellRangerGenome(creature=\"Homo_sapiens\", alias=\"GRCh38\", version=\"3.0.0\", path=\"$GENOMES_DIR/genomes/cellranger-3.0.0/refdata-cellranger-GRCh38-3.0.0\"); \
#g.save()" \
#| /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import CellRangerGenome; \
#g=CellRangerGenome(creature=\"Homo_sapiens\", alias=\"hg19\", version=\"3.0.0\", path=\"$GENOMES_DIR/genomes/cellranger-3.0.0/refdata-cellranger-hg19-3.0.0\"); \
#g.save()" \
#| /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import CellRangerGenome; \
#g=CellRangerGenome(creature=\"Mus_musculus\", alias=\"mm10\", version=\"3.0.0\", path=\"$GENOMES_DIR/genomes/cellranger-3.0.0/refdata-cellranger-mm10-3.0.0\"); \
#g.save()" \
#| /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#  echo "from analysis.models import CellRangerGenome; \
#g=CellRangerGenome(creature=\"Homo_sapiens_and_Mus_musculus\", alias=\"hg19-and-mm10\", version=\"3.0.0\", path=\"$GENOMES_DIR/genomes/cellranger-3.0.0/refdata-cellranger-hg19-and-mm10-3.0.0\"); \
#g.save()" \
#| /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
#
#fi

#####################################################



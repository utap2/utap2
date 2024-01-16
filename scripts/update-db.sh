

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


  echo "from analysis.models import CustomUser; 
if not CustomUser.objects.filter(username='admin').exists(): 
          CustomUser.objects.create_superuser('admin', '$REPLY_EMAIL', '$ADMIN_PASS')" |  /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell


  # Update DB with the genomes and annotations:

  # Remove old genomes and annotations:
  declare -a genomes_db=("StarGenome","StarAnnotation","CellRangerGenome","Bowtie2Genome","TssFile","AllGenomes","BlackList","ChromosomeInfo","Bowtie1Rrna","InterMine")
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
  declare -a black_lists="$GENOMES_DIR/black_lists"
  
  if [ -d "$genomes_path_star/homo_sapiens" ]; then
    echo "from analysis.models import StarGenome, Bowtie2Genome, Bowtie1Rrna, ChromosomeInfo, AllGenomes, BlackList, InterMine, StarAnnotation, TssFile; \
    sh=StarGenome(creature=\"Homo_sapiens\", alias=\"hg38\", version=38.0, source=\"iGenomes\", path=\"$genomes_path_star/homo_sapiens/hg38/star_index/\"); \
    sh.save(); \
    bh=Bowtie2Genome(creature=\"Homo_sapiens\", alias=\"hg38\", version=38.0, source=\"iGenomes\", path=\"$genomes_path_bowtie2/homo_sapiens/hg38/bowtie2_index/genome\", fasta=\"$genomes_path_bowtie2/homo_sapiens/hg38/fasta/genome.fa\"); \
    bh.save(); \
    b1h=Bowtie1Rrna(creature=\"Homo_sapiens\", alias=\"hg38\",path=\"$genomes_path_bowtie1_rRNA/homo_sapiens/hg38/bowtie1_rRNA_index/rRNA\", fasta=\"$genomes_path_bowtie1_rRNA/homo_sapiens/hg38/fasta/rRNA_hg38.fasta\"); \
    b1h.save(); \
    ch=ChromosomeInfo(genome=bh, creature=\"Homo_sapiens\", alias=\"hg38\", path=\"$chromosomes_sizes/homo_sapiens/hg38/hg38.chrom.sizes\"); \
    ch.save(); \
    ah=AllGenomes(creature=\"Homo_sapiens\", alias=\"hg38\", star_genome=sh, bowtie2_genome=bh, bowtie1_rRNA=b1h, chromosomes_sizes=ch); \
    ah.save(); \
    BlackList(genome=bh,creature=\"Homo_sapiens\", alias=\"hg38\", path=\"$black_lists/homo_sapiens/hg38/hg38-blacklist.v2.bed\").save(); \
    InterMine(interMine_creature=\"H. sapiens\", genome=sh, creature=\"Homo_sapiens\", alias=\"hg38\", interMine_web_query=\"http:\/\/www.humanmine.org\/humanmine\", intermine_web_base=\"INTERMINE_WEB_QUERY\").save(); \
    StarAnnotation(genome=sh,bowtie2_genome=bh,all_genome=ah,creature=\"Homo_sapiens\", alias=\"Refseq\", version=38.0, source=\"refGene\", path=\"$genomes_path_star/homo_sapiens/hg38/annotation/refseq/hg38.genes.gtf\", path3p=\"$genomes_path_star/homo_sapiens/hg38/annotation/refseq/hg38.genes.3utr.gtf\", path_UTR_CDS=\"$genomes_path_star/homo_sapiens/hg38/annotation/cds_utr_without_overlap/hg38_cds_UTR_without_overlap.gtf\").save(); \
    StarAnnotation(genome=sh,bowtie2_genome=bh,all_genome=ah,creature=\"Homo_sapiens\", alias=\"genecode\", version=38.0, source=\"genecode\", path=\"$genomes_path_star/homo_sapiens/hg38/annotation/gencode/hg38-gencode.genes.gtf\", path3p=\"$genomes_path_star/homo_sapiens/hg38/annotation/gencode/hg38-gencode.genes.3utr.gtf\", path_UTR_CDS=\"$genomes_path_star/homo_sapiens/hg38/annotation/cds_utr_without_overlap/hg38_cds_UTR_without_overlap.gtf\").save()" \ | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
  fi
  
  
  if [ -d "$genomes_path_star/mouse" ]; then
    echo "from analysis.models import StarGenome, Bowtie2Genome, Bowtie1Rrna, ChromosomeInfo, AllGenomes, BlackList, InterMine, StarAnnotation, TssFile; \
    sm=StarGenome(creature=\"Mus_musculus\", alias=\"mm10\", version=10.0, source=\"iGenomes\", path=\"$genomes_path_star/mouse/mm10/star_index/\"); \
    sm.save(); \
    bm=Bowtie2Genome(creature=\"Mus_musculus\", alias=\"mm10\", version=10.0, source=\"iGenomes\", path=\"$genomes_path_bowtie2/mouse/mm10/bowtie2_index/mm10\", fasta=\"$genomes_path_bowtie2/mouse/mm10/fasta/genome.fa\"); \
    bm.save(); \
    TssFile(genome=bm, creature=\"Mus_musculus\", alias=\"+-2500\", version=10.0, source=\"gencode\",path=\"$tss_files/mouse/mm10/mm10.TSS_+2500_-2500_uniqueProm.bed\").save(); \
    TssFile(genome=bm, creature=\"Mus_musculus\", alias=\"+-500\", version=10.0, source=\"gencode\",path=\"$tss_files/mouse/mm10/mm10.TSS_+500_-500_uniqueProm.bed\").save(); \
    cm=ChromosomeInfo(genome=bm, creature=\"Mus_musculus\", alias=\"mm10\", path=\"$chromosomes_sizes/mouse/mm10/mm10.chrom.sizes\"); \
    cm.save(); \
    BlackList(genome=bm,creature=\"Mus_musculus\", alias=\"mm10\", path=\"$black_lists/mouse/mm10/mm10-blacklist.v2.bed\").save(); \
    InterMine(interMine_creature=\"M. musculus\", genome=sm, creature=\"Mus_musculus\", alias=\"mm10\", interMine_web_query=\"http:\/\/www.mousemine.org\/mousemine\", intermine_web_base=\"INTERMINE_WEB_QUERY\").save(); \
    StarAnnotation(genome=sm,bowtie2_genome=bm,creature=\"Mus_musculus\", alias=\"Refseq\", version=10.0, source=\"iGenomes\", path=\"$genomes_path_star/mouse/mm10/annotation/refseq/mm10.genes.gtf\", path3p=\"$genomes_path_star/mouse/mm10/annotation/refseq/mm10.genes.3utr.gtf\").save(); \
    StarAnnotation(genome=sm,bowtie2_genome=bm,creature=\"Mus_musculus\", alias=\"gencode\", version=10.0, source=\"gencode\", path=\"$genomes_path_star/mouse/mm10/annotation/gencode/mm10-gencode.genes.gtf\", path3p=\"$genomes_path_star/mouse/mm10/annotation/gencode/mm10-gencode.genes.3utr.gtf\").save();" \ | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
  fi


  if [ -d "$genomes_path_star/zebra_fish" ]; then
    echo "from analysis.models import StarGenome, Bowtie2Genome, Bowtie1Rrna, ChromosomeInfo, AllGenomes, BlackList, InterMine, StarAnnotation, TssFile; \
    g=StarGenome(creature=\"Danio_rerio\", alias=\"danRer11\", version=11.0, source=\"iGenomes\", path=\"$genomes_path_star/zebra_fish/danRer11/star_index/\"); \
    g.save(); \
    InterMine(interMine_creature=\"D. rerio\", genome=g, creature=\"Zebrafish\", alias=\"danRer11\", interMine_web_query=\"	http:\/\/www.zebrafishmine.org\", intermine_web_base=\"INTERMINE_WEB_QUERY\").save(); \
    StarAnnotation(genome=g,creature=\"Danio_rerio\", alias=\"iGenomes-Refseq\", version=10.0, source=\"iGenomes-Refseq\", path=\"$genomes_path_star/zebra_fish/danRer11/annotation/refseq/danRer11.genes.gtf\", path3p=\"$genomes_path_star/zebra_fish/danRer11/annotation/refseq/danRer11.genes.3utr.gtf\").save();" \ | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py shell
  fi
fi
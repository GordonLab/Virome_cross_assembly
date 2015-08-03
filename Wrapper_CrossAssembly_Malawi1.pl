#!/usr/bin/perl -w

# Written by Alejandro Reyes
## For a given prefix will run the whole assembly pipeline

use strict;

if (@ARGV != 1) {
  die "\n\nUsage: Wrapper_CrossAssembly_Malawi.pl <Prefix> > LogFile\n\tIs going to be called on a family of files. All named starting by prefix (Ma_F112)T1.1.1.1.fna\n\n";
}

my $dir=`pwd`;
chomp $dir;

my $prefix = shift;
my $nd= "$dir/$prefix";
my $search = $prefix."*.fasta";

my @list=`ls $search`;

# First is going to make a folder for the assembly
die ("No files starting with prefix\n") unless (scalar(@list) >= 1);

system ("mkdir $nd");
# For each file is going to move them into the folder and then join all the reads in a master file and write the sample specific commands
foreach my $f (@list){
  chomp ($f);
  die ("Can't read file $f\n") unless (-e "$f");
  system ("mv $f $nd/.");
  system ("cd $nd; cat $f >> $prefix\_allReads.fna;");
  my $sample=$f;
  $sample =~ s/\.fasta$//;
  system ("cd $nd; echo 'cd-hit-est -i $f -o $sample\_cd-hit.fna -c 0.9 -l 200 -d 0 -mask NX; Parse_CD-Hit-Top5_singleFile.pl $sample\_cd-hit.fna.clstr | cut -f 3 | grep \">\" -v > $sample\_ToGet_UniqueTop5.txt; GetSequences.pl  $sample\_ToGet_UniqueTop5.txt $f > $sample\_UniqueTop5.fna; runAssembly -mi 90 -ml 20% -cpu 4 -large -m -noinfo -numn 3 -rip -verbose -o $sample.assembly $sample\_UniqueTop5.fna; Fasta_chopLowQualEdges.pl $sample.assembly/454LargeContigs.fna > $sample\_largeContigs.fna; fr-hit -a $f -d $sample\_largeContigs.fna -o $sample\_MapReads.txt -c 95; FR-Hit_processReads_map.pl $sample\_MapReads.txt $sample\_largeContigs.fna  $f $sample; Fasta_addNameHeader.pl $sample\_largeContigs.fna _largeContigs.fna >> AllLargeContigs.fasta; cat $sample.left.fna >> Allreads_left.fna; cat $sample.chimera.txt >> Allreads_chimera.txt; cat $sample.edges.fna >> Allreads_edges.fna' >> ToRun_PerSample.txt;");
}

# submit and wait for the jobs
system ("cd $nd; nq ToRun_PerSample.txt | qsub -P long -l h_vmem=10G;");

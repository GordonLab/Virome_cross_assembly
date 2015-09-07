#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives the output of FR-Hit and the multifasta file used as FR-Hit database. Returns a multifasta file where the contigs has been renamed starting with a new count adding the median coverage and the length
#
# Usage: FR-Hit_RenameFinalContigs.pl <Fasta_file> <Output_FR-Hit> <Contigs> > <output>
#
# Input: A multifasta file used as database for FR-Hit and the output of FR-hit mapping of the reads to the database.
# Output:A multifasta file where the contigs has been renamed starting with a new count adding the median coverage and the length
# Note:
# Created: March 19 2013
# Last-updated: Sept 06 2015

use strict;


die ("Usage: FR-Hit_RenameFinalContigs.pl <Output_FR-Hit> <Contigs> > <output>\n") unless (scalar(@ARGV) == 2);



my $file = shift @ARGV;
my $fna = shift @ARGV;
my @seqs=();

open (IN, "<$file") or die ("Couldn't open file: $file\n");
open (FNA, "<$fna") or die ("Couldn't open file: $fna\n");

my %length=();
my %seqs=();
my $name="";

while (my $j = <FNA>){
  chomp($j);
  if ($j =~ /^>(\S+)\s*\.*$/){
    $name=$1;
    $name =~ s/\s+//;
  }else{
    $seqs{$name}.=$j;
    $length{$name}=length($seqs{$name});
  }
}
close FNA;


my %genomes=();
my $old="";
my $n="";

while (my $l = <IN>){
  chomp ($l);
  my @array = split /\t/, $l;
  $n = $array[0];
  $n =~ s/\_\d$//;

  $array[7] =~ s/\%$//;
  $array[1] =~ s/nt$//;
  for (my $i=$array[-2]; $i<=$array[-1]; $i++){
    $genomes{$array[8]}[$i]++; # Calculate the genome coverage per base given the mapping of the reads.
  }
}


my $count=1;
foreach my $k (keys(%genomes)){
  die ("Genome >$k< was not present in the fasta file\n") unless ($length{$k});  #die if the genome mapped was not in the fasta file, meaning if the name was not seen before.
  for (my $i=0; $i<=$length{$k}; $i++){
    $genomes{$k}[$i]=0 unless ($genomes{$k}[$i]);  # fills the coverage for the other bases with zeros.
  }
  my @sort= sort {$a<=>$b} @{$genomes{$k}};
  my $median = $sort[int($length{$k}/2)];  #Calculates the median coverage for each genome
  my $newName=">Contig\_$count\_Median:\_$median\_Len:\_$length{$k}"; #Renames the contigs starting with a new count, gets the median and the length
  $newName.="_circ" if ($k =~ /_circ/);

  print "$newName\n$seqs{$k}\n";
  $count++;
}




#!/usr/bin/perl -w

# Written by Alejandro Reyes
#
#
# Usage: FR-Hit_processReads_map.pl <Output_FR-Hit> <Contigs> <ReadsFile> <Header> 
#
# Input: the output of FR-Hit, the multifasta file used as FR-Hit database, the reads used for mapping and a header for the outfiles
# Output: After parsing the hits it prints in separate files the names of the reads that are potential chimeras, that hit the edge of the contigs of that do not hit any contig
# Note:
# Created: March 14 2013
# Last-updated: Sept 06 2015

use strict;



die ("Usage: FR-Hit_processReads_map.pl <Output_FR-Hit> <Contigs> <ReadsFile> <Header>\n") unless (scalar(@ARGV) == 4);



my $file = shift @ARGV;
my $fna = shift @ARGV;
my $ReadFile = shift @ARGV;
my $Head = shift @ARGV;

open (IN, "<$file") or die ("Couldn't open file: $file\n");
open (FNA, "<$fna") or die ("Couldn't open file: $fna\n");
open (READS, "<$ReadFile") or die ("Couldn't open file: $ReadFile\n");


my %length=();
my $name="";
my $seq="";

# stores a hash with the sequence lengths
while (my $j = <FNA>){
  chomp($j);
  if ($j =~ /^>(\S+)/){
    $name=$1;
    $seq="";
  }else{
    $seq.=$j;
    $length{$name}=length($seq);
  }
}
close FNA;

print "Done with the FNA\n";

# process the mapping file
my %used=();
my %chimeric=();
my %edge=();
my %potChimeric=();

while (my $l = <IN>){
  chomp ($l);
  my @array = split /\t/, $l;
  # ReadName[0] LenRead(nt)[1], eval[2], lenAln[3], StartR[4], StopR[5], Strand[6], PerID(%)[7], ContigName[8], StartC[9], StopC[10]
  $array[7] =~ s/\%$//;
  $array[1] =~ s/nt$//;

  my $perUsed = $array[3]/$array[1];
  if ($perUsed > 0.75){
    $used{$array[0]}=1;
   }else{
    next if ($used{$array[0]});
    next if ($chimeric{$array[0]});
    my $missed = $array[1]-$array[3];
    my $min = $array[9] < ($length{$array[8]} - $array[10]) ? $array[9] : $length{$array[8]} - $array[10];	
    if (($missed > $min) && (not defined $potChimeric{$array[0]})){
      $edge{$array[0]}=1;
      $used{$array[0]}=1;
    }else{
      my @coords=sort {$a<=>$b} ($array[4], $array[5]);
      if ($potChimeric{$array[0]}){
	foreach my $k (keys (%{$potChimeric{$array[0]}})){
	  my $st=$coords[0]<$potChimeric{$array[0]}{$k}[0] ? $coords[0] : $potChimeric{$array[0]}{$k}[0];
	  my $sp=$coords[1]>$potChimeric{$array[0]}{$k}[1] ? $coords[1] : $potChimeric{$array[0]}{$k}[1];
	  my $len = $sp - $st;
	  # if the sum of the lengths is < 1.5 times the max distance then is a chimera
	  my $overlap=(($coords[1]-$coords[0])+($potChimeric{$array[0]}{$k}[1]-$potChimeric{$array[0]}{$k}[0]))/$len;
	  $chimeric{$array[0]}=1 if ($overlap < 1.5);
	  $used{$array[0]}=1 if ($overlap < 1.5);
	}
      }
      @{$potChimeric{$array[0]}{$array[8]}}=($coords[0],$coords[1]) if ($array[3] > 50);
    }
  }
}
close IN;
print "Done with Map\n";

$name="";
my $read_seq="";
open (OUTC, ">$Head.chimera.txt") or die ("Couldn't open file: $Head.chimera.txt\n");
open (OUTE, ">$Head.edges.fna") or die ("Couldn't open file: $Head.edges.fna\n");
open (OUTL, ">$Head.left.fna") or die ("Couldn't open file: $Head.left.fna\n");

while (my $t =<READS>){
  chomp ($t);
  if ($t=~ /^>/){
    $t=~s/>//;
    if ($name ne ""){
      print OUTC $name."\n" if ($chimeric{$name});
      print OUTE ">$name\n$read_seq\n" if ($edge{$name});
      print OUTL ">$name\n$read_seq\n"  unless ($used{$name} or $potChimeric{$name});
    }
    $name = $t;
    $read_seq="";
  }else{
    $read_seq.=uc($t);
  }
}
print OUTC $name."\n" if ($chimeric{$name});
print OUTE ">$name\n$seq\n" if ($edge{$name});
print OUTL ">$name\n$seq\n"  unless ($used{$name});
close READS;
close OUTC;
close OUTE;
close OUTL;

#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Split contigs in a point if coverage is 1 for over 15nt OR ratio between coverage and +- 10 is greater than 100 or if coverage is low (<20) and ratio is >10.
# Print subcontig if larger than 50
#
# Usage: FR-Hit_cleanChimera.pl <Output_FR-Hit> <Contigs> > <output> 
#
# Input: the output of FR-Hit, the multifasta file used as FR-Hit database
# Output: A multifasta files with the contigs after splitting on potential chimeric points and subcontigs if > 50nt.
# Note:
# Created: March 16 2013
# Last-updated: Sept 06 2015

use strict;

die ("Usage: FR-Hit_cleanChimera.pl <Output_FR-Hit> <Contigs> > <output>\n") unless (scalar(@ARGV) == 2);

my $file = shift @ARGV;
my $fna = shift @ARGV;
my @seqs=();

open (IN, "<$file") or die ("Couldn't open file: $file\n");
open (FNA, "<$fna") or die ("Couldn't open file: $fna\n");

my %length=();
my %seqs=();
my $name="";

# Stores sequences and lengths in hashes
while (my $j = <FNA>){
  chomp($j);
  if ($j =~ /^>(\S+)/){
    $name=$1;
  }else{
    $j=~s/[^ATCGatcg]/X/;	
    $seqs{$name}.=uc($j);
    $length{$name}=length($seqs{$name});
  }
}
close FNA;

my %genomes=();
my $n="";
while (my $l = <IN>){
  chomp ($l);
  my @array = split /\t/, $l;
  $n = $array[0];
  $n =~ s/\_\d$//;
  $array[7] =~ s/\%$//;
  $array[1] =~ s/nt$//;
  
  next if ($array[7] < 95);   # Next if the percent id is less than 95% 
  die ("No length for contig >$array[8]<\n") unless $length{$array[8]}; 
  # Next unless the percent covered is over 95% of the read or is in the first or last 5bp
  next unless ((($array[3]/$array[1]) >= 0.95) or ($array[-2]< 5) or ($array[-1] > ($length{$array[8]}-5)));   
  # For each position of the hit on the read, will store: On 0->Is covered by the read, on 1-> if read starts and finish +- 10bp 
  for (my $i=$array[-2]; $i<=$array[-1]; $i++){
    $genomes{$array[8]}[$i-1][0]++; # Marks the coverage of all sequences
    if ($i > ($array[-2]+10) && $i < ($array[-1]-10)){
       $genomes{$array[8]}[$i-1][1]++;
    }elsif (($i <= 12) && $i < ($array[-1]-10)){
       $genomes{$array[8]}[$i-1][1]++;
    }elsif (($i > ($array[-2]+10)) && ($i >= ($length{$array[8]}-12))){
       $genomes{$array[8]}[$i-1][1]++;
    }
  }
}
close IN;

foreach my $k (keys(%genomes)){
  my $cov=0;
  die ("Unknown genome >$k<\n") unless ($length{$k});
  for (my $i=0; $i<$length{$k}; $i++){
    $genomes{$k}[$i][0]=0 unless ($genomes{$k}[$i][0]);
    $genomes{$k}[$i][1]=1 unless ($genomes{$k}[$i][1]);
    $genomes{$k}[$i][2]=sprintf("%.2f",$genomes{$k}[$i][0]/$genomes{$k}[$i][1]);
    # Split in a point if coverage is 1 for over 15nt OR ratio between coverage and +- 10 is greater than 100 or if coverage is low (<20) and ratio is >10.
    if ($genomes{$k}[$i][0] == 1){
      $cov++;
    }else{
      $cov=0;
    }
    substr $seqs{$k}, $i, 1, "N" if ((($genomes{$k}[$i][1] < 20) && ($genomes{$k}[$i][2] > 10)) or ($genomes{$k}[$i][2] > 50) or ($cov > 150));
  }
  
  my @split = split /N+/, $seqs{$k};
  for (my $h =0; $h<@split; $h++){
    print ">$k\_$h\n$split[$h]\n" if (length($split[$h]) > 50); #Print subcontig if larger than 50
  }
}




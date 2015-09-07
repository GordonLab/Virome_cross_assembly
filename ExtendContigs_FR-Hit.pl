#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Foreach contig, using the fr-hit outfile it identifies hits to the edges. If more than 4 reads map partially to the edges it retrieve the reads and use phrap with default parameters to extend the contig. From the resulting contig it takes the longest contig and print it to extended contigs
#
# Usage: ExtendContigs_FR-Hit.pl <FR-Hit-outfile> <ContigFile> <ReadsFile> 
#
# Input: the output of FR-Hit, the multifasta file used as FR-Hit database and the mapped reads
# Output: Generated a Log file, two temp files (ToGet.txt and ToAssemble.fna) which are removed later and a ExtendedContigs.fna with the succesfully extended contigs.
# Note:
# Created: March 14 2013
# Last-updated: Sept 06 2015

use strict;

if (@ARGV != 3){
  die ("\nUsage: ExtendContigs_FR-Hit.pl <FR-Hit-outfile> <ContigFile> <ReadsFile>\n");
}

my $tablefile =shift;
open (TABLE, "<$tablefile") or die ("Couldn't open file $tablefile\n");
my $contig =shift;
open (IN, "<$contig") or die ("Couldn't open file $contig\n");
my $readsFile =shift;

# Reads the contig file and store the sequences and the lengths in hashes.
my %seqs=();
my %length=();
my $name="";
while (my $l=<IN>){
  chomp($l);
  next unless ($l=~/\S+/);
  if ($l=~/^>(\S+)/){
    $name=$1;
  }else{
    $seqs{$name}.=$l;
    $length{$name}=length($seqs{$name});
  }
}
close IN;

my %contigs=();
while (my $line =<TABLE>){
  chomp $line;
  next unless ($line =~ /\w+/);
  next if ($line =~ /_circ/);   # Skip contigs that were described as circular
  my @temp= split /\s+/, $line;
  $temp[1]=~s/nt//;
  my $ret="";
  $ret.= $temp[6] eq "+" ? "0" : "1"; # Depending on the orientation of the hit assign a 0 (+) or 1 (-)
  my @coords = sort {$a <=> $b} ($temp[4], $temp[5]);
  $ret.= $coords[0] < ($temp[1]-$coords[1]) ? "0" : "1";
  $ret.= $temp[-2] < ($length{$temp[-3]} - $temp[-1]) ? "0" : "1";
  push @{$contigs{$temp[-3]}}, $temp[0] if ($ret =~/010|001|110|101/); # if the reads hit partially the end is sent to the array stored in the hash with the contig key
}
close TABLE;



my @seqsKeys = keys %seqs;
my @contigKeys = keys %contigs;

open (LOG, ">ExtendContig_log.txt") or die ("Couldn't open file: ExtendContig_log.txt\n");
print LOG "A total of ".scalar(@seqsKeys)." contigs with ".scalar(@contigKeys)." contigs that can potentially extended.\n";
foreach my $k (keys %contigs){  # foreach contig try to extend the assembly.
  my $printLine = join ("\n", @{$contigs{$k}});
  if (scalar(@{$contigs{$k}}) > 4){ #only try to extend the contigs if more than 4 reads map the edge
    open (OUT, ">ToAssemble.fna") or die ("Couldn't open file: ToAssemble.fna\n");
    print OUT ">$k\n$seqs{$k}\n";
    close OUT;
    open (GET, ">ToGet.txt") or die ("Couldn't open file: ToGet.txt\n");  
    print GET "$printLine\n";
    close GET;
    system("GetSequences.pl ToGet.txt $readsFile >> ToAssemble.fna"); # Gets the reads and append them to the contigs
    system("phrap ToAssemble.fna"); # runs phrap on the assembled files
    open (TEM, "<ToAssemble.fna.contigs") or die ("Couldn't open ToAssemble.fna.contigs\n"); # load the assembled file
    my $count=1;
    my %assem=();
    my %len=();
    while (my $y=<TEM>){
      chomp($y);
      if($y=~/^>/){
	$count++;
      }else{
	$assem{$count}.=$y;
	$len{$count}=length($assem{$count});
      }
    }
    my @sortK=sort {$len{$b}<=>$len{$a}} keys %len;
    system("echo '>$k' >> ExtendedContigs.fna");
    system("echo '$assem{$sortK[0]}' >> ExtendedContigs.fna");  # Keeps only the longest contigs (which should include the original contig)
    system("rm ToGet.txt; rm ToAssemble.fna*");
    print LOG "Finished extending contig $k with total of $count contigs the longest been $len{$sortK[0]}\n";
  }
  print LOG $k."\t".scalar(@{$contigs{$k}})."\n";
}
close LOG;    


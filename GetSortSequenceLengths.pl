#!/usr/bin/perl -w


use strict;

if (@ARGV != 2) {
	die "\nUsage: GetSeqeunceLengths.pl <FastaFile> <header>\n\n";
}


#Reads the Fasta Sequences

my $file = shift @ARGV;
my $head = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my %seqs=();
my %len=();
my $name="";
while (my $line=<IN>){
  chomp $line;
  next unless ($line =~ /\S+/);
  if ($line =~ /^>/){
    $line =~ />(\S+)/;
    $name=$1;
  }else{
    $seqs{$name}.=uc($line);
    $len{$name}=length($seqs{$name});
  }
}
close IN;

my @sortKeys = sort {$len{$b} <=> $len{$a}} keys %len;

open (SEQ, ">$head\_sort.fna") or die ("Couldn't open file: $head\_sort.fna\n");
open (LEN, ">$head\_len.txt") or die ("Couldn't open file: $head\_len.txt\n");

for (my $i=0; $i<@sortKeys; $i++){
  print LEN "$sortKeys[$i]\t$len{$sortKeys[$i]}\n";
  print SEQ ">$sortKeys[$i]\n$seqs{$sortKeys[$i]}\n";
}
close LEN;
close SEQ;

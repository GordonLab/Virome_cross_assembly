#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives a multifasta file and removes the low qualities ends represented by lowercase letters, prints sequences only if longer than 500nt
#
# Usage: Fasta_chopLowQualEdges.pl <Fasta_file> > <output>
#
# Input: A multifasta file
# Output: The same multifasta file where the low quality characters represented by lowercase letters has been removed from the ends. It removes sequences shorted than 500nt
# Note:
# Created: March 16 2013
# Last-updated: Sept 06 2015

use strict;

if (@ARGV != 1) {
  die "\nUsage: Fasta_chopLowQualEdges.pl <FastaFile> > <outfile>\n\n";
}


#Reads the Fasta Sequences

my $file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my $name=<IN>;
chomp $name;
my @names= split (/\s+/, $name);
$name=$names[0];

my $seq=();

while (my $line=<IN>){
  chomp $line;
  next unless ($line =~ /\S+/);
  if ($line =~ /^>/){
    $seq=~ s/^[a-z]+//;   #Removes low qual at start of seq
    $seq=~ s/[a-z]+$//;   #Removes low qual at end of seq
    print "$name\n".uc($seq)."\n" if (length($seq)  > 500);
    $seq="";
    @names=split (/\s+/, $line);
    $name=$names[0];
  }else {
    $seq.=$line;
  }
}
close IN;
$seq=~ s/^[a-z]+//;   #Removes low qual at start of seq
$seq=~ s/[a-z]+$//;   #Removes low qual at end of seq
print "$name\n".uc($seq)."\n" if (length($seq) > 500);

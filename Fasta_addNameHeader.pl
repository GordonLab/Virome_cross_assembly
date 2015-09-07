#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives a multifasta file and a word or prefix to be removes, generates a multifasta file where each sequence has as prefix the name of the file without the word removed
#
# Usage: Fasta_addNameHeader.pl <Fasta_file> <Replace-word> > <output>
#
# Input: A multifasta file
# Output: The same multifasta file where the name of each sequence has been modified to have as prefix the file name after substituting the "Replace-word"
# Note:
# Created: June 20 2014
# Last-updated: Sept 06 2015

use strict;

if (@ARGV !=2) {
  die "\nUsage: Fasta_addNameHeader.pl <FastaFile> <RemoveWord> > <outfile>\n\n";
}


my $file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my $subs = shift @ARGV;
my @file_struct = split /\//, $file;
my $prefix = $file_struct[-1]; #The file name will go after the last "/" i.e. removes the folder names contaninig the file.

$prefix =~ s/$subs//; #substitute $prefix, usually the extention of the file i.e. ".fna"

while (my $line=<IN>){
  chomp $line;
  next unless ($line =~/\S+/);
  if ($line =~ /^>(\S+)/){
    print ">$prefix\|$1\n";
  }else {
    print $line."\n";
  }
}
close IN;

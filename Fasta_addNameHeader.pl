#!/usr/bin/perl -w

# Written by Alejandro Reyes


use strict;

if (@ARGV !=2) {
  die "\nUsage: Fasta_addNameHeader.pl <FastaFile> <RemoveWord> > <outfile>\n\n";
}


#Reads the Fasta Sequences

my $file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my $subs = shift @ARGV;
my @file_struct = split /\//, $file;
my $prefix = $file_struct[-1];

$prefix =~ s/$subs//;

#die("Is going to use $prefix as header\n");
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

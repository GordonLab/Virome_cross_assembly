#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives a Fasta File and a list of names and retrieve the sequences that DOES NOT begin with the name
#
# Usage: GetSequences_inverted.pl "Names_list" "Fasta_File" > "output"
#
# Input: Two files, one with a list of names (without spaces) and the second a Fasta formated file
# Output: A fasta file of sequences where the names were NOT within the list
# Note:
# Created: Aug 11 / 08.
# Last-updated: Sept 06 2015

use strict;

if (@ARGV != 2) {
	die "\nUsage: GetSequences_inverted.pl <Names list> <Fasta File> > <output>\n\n";
}


#Reads the names to get

my $file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my %names = ();

while (my $lines=<IN>) {
  if ($lines =~ /\S+/){
    chomp $lines;
    my @entry = split (/\s+/, $lines); #The name goes from the start of the file until the first white space
    $entry[0] =~ s/^>//;
    $names{$entry[0]}=1;
  }	
}	
close IN;


#Reads the Fasta Sequences

$file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my $counter = 0;
while (my $line = <IN>) {
  if ($line =~ /^>/){
    $counter = 0;
    chomp $line;
    my @temp = split (/\s+/, $line);
    unless ($names{$temp[0]}){
      print ">$line\n";
      $counter = 1;
    }
  }elsif (($line =~ /^\w/) && ($counter == 1)){
    print $line;
  }
}
close IN;

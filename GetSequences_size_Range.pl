#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives a Fasta File and an upper and lower size limits retrieve the sequences that range in that size length
#
# Usage: GetSequences_size_Range.pl <Lower_Size> <Upper_size> <Fasta File> > <output>
#
# Input: upper and lower size limits (integers) and a multifasta file
# Output: a multifasta file with all sequences in the original file within the size range delimeted
# Note:
# Created: April 9 2011
# Last-updated: Sept 06 2015

use strict;

if (@ARGV != 3) {
	die "\nUsage: GetSequences_size_Range.pl <Lower_Size> <Upper_size> <Fasta File> > <output>\n\n";
}


#Reads the names to get

my $lower = shift @ARGV;
my $higher = shift @ARGV;

#Reads the Fasta Sequences

my $file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my $name="";
my $seq="";
while (my $line = <IN>) {
	if ($line =~ /^>/){
		chomp($line);
		if ($name ne ""){
			print "$name\n$seq" if ((length($seq) >= $lower) && (length($seq) <= $higher));
		}
		$name=$line;
		$seq="";
	}else{
		$seq.=$line;
	}
}
print "$name\n$seq" if ((length($seq) >= $lower) && (length($seq) <= $higher));
close IN;

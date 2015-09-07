#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives a Fasta File and a list of names and retrieve the sequences that begin with the name
#
# Usage: GetSequences.pl "Names_list" "Fasta_File" > "output"
#
# Input: Two files, one with a list of names (without spaces) and the second a Fasta formated file
# Output: A fasta file of sequences where the names were within the list
# Note:
# Created: Aug 11 / 08.
# Last-updated: Sept 06 2015

use strict;

if (@ARGV != 2) {
	die "\nUsage: GetSequences.pl <Names list> <Fasta File> > <output>\n\n";
}


#Reads the names to get

my $file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my %names = ();

while (my $lines=<IN>) {
	if ($lines =~ /\S+/){
	chomp $lines;
	my @entry = split (/\s+/, $lines); # The list will be given by the first word in the line until the first space
	$entry[0]=~s/^>//;
	$names{$entry[0]}=1;
	}	
}	
close IN;


#Reads the Fasta Sequences

$file = shift @ARGV;
open (IN, "<$file") or die ("Couldn't open file: $file\n");

my $check = 0;
while (my $line = <IN>) {
	if ($line =~ /^>/){
		$check = 0;
		chomp $line;
		$line =~ s/>//;
		my @temp = split (/\s+/, $line);
		if (exists $names{$temp[0]}){
			print ">$line\n";
			$check = 1;
		}
	}elsif ($check == 1){
		print $line;
	}
	
}
close IN;
exit;

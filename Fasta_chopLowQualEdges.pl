#!/usr/bin/perl -w

# Written by Alejandro Reyes


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

#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives the output of cd-hit-est (cluster file) and generates a file where for each cluster it prints the 5 longest read names (if available)
#
# Usage: Parse_CD-Hit-Top5_singleFile.pl <cd-hit.clstr> > <output>
#
# Input: The clstr output file from cd-hit-est
# Output: The top 5 names of the longest reads from each cluster
# Note:
# Created: April 05 2014
# Last-updated: Sept 06 2015


use strict;

if (@ARGV != 1) {
  die "\nUsage:  Parse_CD-Hit-Top5_singleFile.pl <File.clstr> > <output>\n\n";
}

my $file = shift @ARGV;

#Reads the cluster file

open (IN, "<$file") or die ("Couldn't open file: $file\n");

my %rep = ();
my $name ="";
my $head="";
my @temp=();

while (my $lines=<IN>) {
  chomp $lines;
  if ($lines =~ /^\d/){
    my @elements = split (/\s+/, $lines);
    $elements[1]=~ s/nt,//;
    $elements[2]=~ />(.+)\.\.\.$/;
    $name = $1;
    $head = $name if ($lines =~ /\*$/);
    push @temp, [$elements[1], $name];
  }elsif ($lines =~ /^>/){
    next unless ($name && $head);
    @{$rep{$head}}= (@temp);
    @temp=();
    $name="";
    $head="";
  }
}
close IN;
@{$rep{$head}}= (@temp);
@temp=();
$name="";
$head="";

#Prints the sequences to the output and the statistics;

foreach my $k (keys %rep){
  my @sorted= sort {$b->[0] <=> $a->[0]} @{$rep{$k}};
  print ">$k\n";
  my %seen=();
  my $count=1;
  for (my $j=0; $j<@sorted; $j++){
    next if $seen{$sorted[$j][1]};
    print "\t$sorted[$j][0]\t$sorted[$j][1]\n";
    $seen{$sorted[$j][1]}=1;
    last if ($count==5);
    $count++;
  }
}

#!/usr/bin/perl -w

# Written by Alejandro Reyes
# Receives the output of several runs of cd-hit-est and generates a file for each cluster and some statistics on STDOUT of the clustering.
#
# Usage: Parse_CD-Hit-Top5.pl <highest.clstr> ...<lowest.clstr> > <output>
#

use strict;

if (@ARGV != 1) {
  die "\nUsage:  Parse_CD-Hit-Top5.pl <File.clstr> > <output>\n\n";
}

my $file = shift @ARGV;

#Reads the lowest file

open (IN, "<$file") or die ("Couldn't open file: $file\n");

my %rep = ();
my %parent = ();
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
    for (my $i=0; $i<@temp; $i++){
      $parent{$temp[$i][-1]}=$head;
    }
    @temp=();
    $name="";
    $head="";
  }
}
close IN;
@{$rep{$head}}= (@temp);
for (my $i=0; $i<@temp; $i++){
  $parent{$temp[$i][-1]}=$head;
}
@temp=();
$name="";
$head="";

%parent=();
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

#!/usr/bin/perl -w

use strict;


if (@ARGV != 3){
  die ("\nUsage: ExtendContigs_FR-Hit.pl  <FR-Hit-outfile> <ContigFile> <ReadsFile> > Output\n");
}


my $tablefile =shift;
open (TABLE, "<$tablefile") or die ("Couldn't open file $tablefile\n");
my $contig =shift;
open (IN, "<$contig") or die ("Couldn't open file $contig\n");
my $readsFile =shift;

my %seqs=();
my %length=();
my $name="";
while (my $l=<IN>){
  chomp($l);
  next unless ($l=~/\S+/);
  if ($l=~/^>(\S+)/){
    $name=$1;
  }else{
    $seqs{$name}.=$l;
    $length{$name}=length($seqs{$name});
  }
}
close IN;

my %contigs=();
while (my $line =<TABLE>){
  chomp $line;
  next unless ($line =~ /\w+/);
  next if ($line =~ /_circ/);
  my @temp= split /\s+/, $line;
  $temp[1]=~s/nt//;
  my $ret="";
  $ret.= $temp[6] eq "+" ? "0" : "1";
  my @coords = sort {$a <=> $b} ($temp[4], $temp[5]);
  $ret.= $coords[0] < ($temp[1]-$coords[1]) ? "0" : "1";
  $ret.= $temp[-2] < ($length{$temp[-3]} - $temp[-1]) ? "0" : "1";
  push @{$contigs{$temp[-3]}}, $temp[0] if ($ret =~/010|001|110|101/);
}
close TABLE;



my @seqsKeys = keys %seqs;
my @contigKeys = keys %contigs;

open (LOG, ">ExtendContig_log.txt") or die ("Couldn't open file: ExtendContig_log.txt\n");
print LOG "A total of ".scalar(@seqsKeys)." sequences with ".scalar(@contigKeys)." contig with sequences\n";
foreach my $k (keys %contigs){
  my $printLine = join ("\n", @{$contigs{$k}});
  if (scalar(@{$contigs{$k}}) > 4){
    open (OUT, ">ToAssemble.fna") or die ("Couldn't open file: ToAssemble.fna\n");
    print OUT ">$k\n$seqs{$k}\n";
    close OUT;
    open (GET, ">ToGet.txt") or die ("Couldn't open file: ToGet.txt\n");
    print GET "$printLine\n";
    close GET;
    system("GetSequences.pl ToGet.txt $readsFile >> ToAssemble.fna");
    system("phrap ToAssemble.fna");
    open (TEM, "<ToAssemble.fna.contigs") or die ("Couldn't open ToAssemble.fna.contigs\n");
    my $count=1;
    my %assem=();
    my %len=();
    while (my $y=<TEM>){
      chomp($y);
      if($y=~/^>/){
	$count++;
      }else{
	$assem{$count}.=$y;
	$len{$count}=length($assem{$count});
      }
    }
    my @sortK=sort {$len{$b}<=>$len{$a}} keys %len;
    system("echo '>$k' >> ExtendedContigs.fna");
    system("echo '$assem{$sortK[0]}' >> ExtendedContigs.fna");
    system("rm ToGet.txt; rm ToAssemble.fna*");
    print LOG "Finished extending contig $k with total of $count contigs the longest been $len{$sortK[0]}\n";
    #die ("Finish round 1\n");
  }
  print LOG $k."\t".scalar(@{$contigs{$k}})."\n";
}
close LOG;    


#!/usr/bin/perl -w
use strict;



die ("Usage: DeRepContigs_Blastn.pl <Output_Blastt> <LenFile> <Contigs> > <output>\n") unless (scalar(@ARGV) == 3);



my $blast = shift @ARGV;
my $len = shift @ARGV;
my $fna = shift @ARGV;


open (LEN, "<$len") or die ("Couldn't open file: $len\n");

my %length=();
my $name="";

while (my $j = <LEN>){
  chomp($j);
  my @arr=split /\s+/, $j;
  $length{$arr[0]}=$arr[1];
}
close LEN;

my %removed=();
my %circular=();
my %kept=();
my %eval=();
my $last="";
my @seqBlast=();

open (IN, "<$blast") or die ("Couldn't open file: $blast\n");
while (my $l=<IN>){
  chomp ($l);
  my @arr=split /\s+/, $l;
  next unless ($length{$arr[0]} && $length{$arr[1]}); 
  next if (($arr[0] eq $arr[1]) && ($arr[3] == $length{$arr[0]}));
  next unless ($arr[2]>90);
  if ($arr[0] ne $last && $last ne ""){
    &analyze_hit(\@seqBlast, \%kept, \%removed, \%circular, \%eval) unless $removed{$seqBlast[0][0]};
    @seqBlast=();
  }
  $last=$arr[0];
  push @seqBlast, [@arr];
}
close IN;
if ($last ne ""){
  &analyze_hit(\@seqBlast, \%kept, \%removed, \%circular, \%eval) unless $removed{$seqBlast[0][0]};
}

open (FNA, "<$fna") or die ("Couldn't open file: $fna\n");
my $rename="";
my $seq="";
my $na="";
while (my $t = <FNA>){
  chomp($t);
  if($t =~ /^>/){
    unless ($na eq "" || $removed{$na}){
      $rename=$na."_L".$length{$na};
      $rename.="_circ" if ($circular{$na});
      print ">$rename\n$seq\n";
    }
    $t=~/^>(.+)\s*/;
    $na=$1;
    $seq="";
  }else{
    $seq.=uc($t) if ($t=~/\S+/);
  }
}
unless ($na eq "" || $removed{$na}){
  $rename=$na."_L".$length{$na};
  $rename.="_circ" if ($circular{$na});
  print ">$rename\n$seq\n";
}


#Subroutines

sub analyze_hit{
  my @seq = @{$_[0]};
  my $keep = $_[1];
  my $removed = $_[2];
  my $circular = $_[3];
  my $eval=$_[4];

  for (my $i=0; $i<@seq; $i++){
    return if (${$removed}{$seq[$i][0]});
    ${$keep}{$seq[$i][0]}=1;
    my @coords = sort {$a <=> $b} ($seq[$i][8], $seq[$i][9]);
    if ($seq[$i][0] eq $seq[$i][1]){
      if ($coords[0] == $seq[$i][8]){
	${$circular}{$seq[$i][0]}=1 if (($seq[$i][3] > $seq[$i][6]) && ($seq[$i][3] > ($length{$seq[$i][1]}-$seq[$i][9])));
	${$circular}{$seq[$i][0]}=2 if (($seq[$i][3] > $seq[$i][8]) && ($seq[$i][3] > ($length{$seq[$i][0]}-$seq[$i][7])));
      }
    }else{
      for (my $j=$coords[0]; $j<=$coords[1]; $j++){
	${$eval}{$seq[$i][1]}[$j]=1;
      }
    }
  }

  my $count=0;
  for (my $s=0; $s<$#{${$eval}{$seq[0][0]}}; $s++){
    $count++ if ($eval{$seq[0][0]}[$s]);
  }
  die ("Length of >$seq[0][0]< not defined\n") unless ($length{$seq[0][0]});
  $count=$count/$length{$seq[0][0]};
  ${$removed}{$seq[0][0]}=1 if ($count > 0.9);
}

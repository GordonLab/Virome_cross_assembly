#!/usr/bin/perl -w

# Written by Alejandro Reyes
# For a given prefix will run the whole assembly pipeline
# Is going to be called on a family of files. All named starting by prefix i.e (Ma_F112)T1.1.1.1.fna\n\n";
#
# Usage: Wrapper_CrossAssembly_Malawi.pl <Prefix> > LogFile
#
# Input: A prefix that should be the name of the folder where the wrapper 1 was ran.
# Output: Runs the whole pipeline generating several files.
# Note:
# Created: June 16 2014.
# Last-updated: Sept 06 2015

use strict;

if (@ARGV != 1) {
  die "\n\nUsage: Wrapper_CrossAssembly_Malawi.pl <Prefix> > LogFile\n\tIs going to be called on a family of files. All named starting by prefix (Ma_F112)T1.1.1.1.fna\n\n";
}

my $dir=`pwd`;
chomp $dir;

my $prefix = shift;
my $nd= "$dir/$prefix";

# on joined large contigs is going to de-replicate and determine which are circular.
system ("cd $nd; GetSortSequenceLengths.pl AllLargeContigs.fasta AllLargeContigs;");
system ("cd $nd; makeblastdb -in AllLargeContigs_sort.fna -dbtype nucl;");
system ("cd $nd; blastn -query AllLargeContigs_sort.fna -db AllLargeContigs_sort.fna -outfmt 6 -evalue 1e-5 > OutSelfBlast.txt;");
system ("cd $nd; DeRepCircContigs_Blastn.pl OutSelfBlast.txt AllLargeContigs_len.txt AllLargeContigs_sort.fna > DeRep_LargeContigs.fna;");

# Map the left reads to all the contigs and see which are left and which may help with edges.
system ("cd $nd; fr-hit -a Allreads_left.fna -d DeRep_LargeContigs.fna -o MapReads_Left1.txt -c 95;");
system ("cd $nd; FR-Hit_processReads_map.pl MapReads_Left1.txt DeRep_LargeContigs.fna Allreads_left.fna AllReads_round1;");

# The reminding reads should be used for a new de novo assembly. Use strategy again of top read + 5.
system ("cd $nd; cd-hit-est -i AllReads_round1.left.fna -o AllReads_round1_cd-hit.fna -c 0.9 -l 200 -d 0 -mask NX;");
system ("cd $nd; Parse_CD-Hit-Top5_singleFile.pl AllReads_round1_cd-hit.fna.clstr | cut -f 3 | grep \">\" -v > AllReads_round1_UniqueTop5.txt;");
system ("cd $nd; GetSequences.pl AllReads_round1_UniqueTop5.txt AllReads_round1.left.fna >  AllReads_round1_UniqueTop5.fna;");
system ("cd $nd; runAssembly -force -mi 90 -large -m -noinfo -numn 3 -rip -verbose -o Assembly_round1 AllReads_round1_UniqueTop5.fna;");

# Re-name long contigs, edit quality and cat with previous long contigs.
system ("cd $nd; Fasta_chopLowQualEdges.pl Assembly_round1/454LargeContigs.fna > LargeContigs_round1.fna;");
system ("cd $nd; Fasta_addNameHeader.pl LargeContigs_round1.fna .fna >> AllLargeContigs_round2.fna;");
system ("cd $nd; cat DeRep_LargeContigs.fna >> AllLargeContigs_round2.fna;");

# De replicate new large set of contigs.
system ("cd $nd; GetSortSequenceLengths.pl AllLargeContigs_round2.fna AllLargeContigs_round2;");
system ("cd $nd; makeblastdb -in AllLargeContigs_round2_sort.fna -dbtype nucl;");
system ("cd $nd; blastn -query AllLargeContigs_round2_sort.fna -db AllLargeContigs_round2_sort.fna -outfmt 6 -evalue 1e-5 > OutSelfBlast_round2.txt;");
system ("cd $nd; DeRepCircContigs_Blastn.pl OutSelfBlast_round2.txt AllLargeContigs_round2_len.txt AllLargeContigs_round2_sort.fna > DeRep_LargeContigs_round2.fna;");

# Map the reads to the contigs and see how many were used.
system ("cd $nd; fr-hit -a AllReads_round1.left.fna -d DeRep_LargeContigs_round2.fna -o MapReads_Left2.txt -c 95;");
system ("cd $nd; FR-Hit_processReads_map.pl MapReads_Left2.txt DeRep_LargeContigs_round2.fna AllReads_round1.left.fna AllReads_round2;");

# Join all the 'edge' files and try to use them to extend contigs.
system ("cd $nd; cat Allreads_edges.fna AllReads_round1.edges.fna AllReads_round2.edges.fna > ForEdges_round2.fna;");
system ("cd $nd; fr-hit -a ForEdges_round2.fna -d DeRep_LargeContigs_round2.fna -o MapReads_edges -c 95;");
system ("cd $nd; ExtendContigs_FR-Hit.pl MapReads_edges DeRep_LargeContigs_round2.fna ForEdges_round2.fna > ToCheck_Extension.txt;");

# put together extended contigs and other contigs, separate the circular ones, try phrap to potentially join contigs
system ("cd $nd; grep \">\" ExtendedContigs.fna > ToGet_inverted.txt;");
system ("cd $nd; GetSequences_inverted.pl ToGet_inverted.txt DeRep_LargeContigs_round2.fna >> ExtendedContigs.fna;");
system ("cd $nd; grep \"_circ\" ExtendedContigs.fna > ToGet_nonCirc.txt;");
system ("cd $nd; GetSequences_inverted.pl ToGet_nonCirc.txt ExtendedContigs.fna > ToPhrap_contigs.fna;");
system ("cd $nd; phrap -minmatch 20 -maxmatch 20 -bandwidth 5 -minscore 20 -gap_ext -4 ToPhrap_contigs.fna;");
system ("cd $nd; cat ToPhrap_contigs.fna.contigs ExtendedContigs.fna > Phrap_contigs.fna;");

# De-replicate contigs and map All reads except chimeric.
system ("cd $nd; GetSortSequenceLengths.pl Phrap_contigs.fna Phrap_contigs;");
system ("cd $nd; makeblastdb -in Phrap_contigs_sort.fna -dbtype nucl;");
system ("cd $nd; blastn -query Phrap_contigs_sort.fna -db Phrap_contigs_sort.fna -outfmt 6 -evalue 1e-5 > OutSelfBlast_phrap.txt;");
system ("cd $nd; DeRepCircContigs_Blastn.pl OutSelfBlast_phrap.txt Phrap_contigs_len.txt Phrap_contigs_sort.fna > DeRep_PhrapContigs.fna;");
system ("cd $nd; cat Allreads_chimera.txt AllReads_round1.chimera.txt AllReads_round2.chimera.txt > ChimericReads_round2.txt;");
system ("cd $nd; GetSequences_inverted.pl ChimericReads_round2.txt $prefix\_allReads.fna > All_reads_nonChimera.fna;");
system ("cd $nd; fr-hit -a All_reads_nonChimera.fna -d DeRep_PhrapContigs.fna -o Map_FinalReads.txt -c 95;");

# Check for final chimeras in the contigs. Then do final size selection and rename the final contigs.
system ("cd $nd; FR-Hit_cleanChimera.pl Map_FinalReads.txt DeRep_PhrapContigs.fna > Final_nonChimeriContigs.fna;");
system ("cd $nd; GetSequences_size_Range.pl 500 1000000 Final_nonChimeriContigs.fna > FinalSizeSelected.fna;");
system ("cd $nd; fr-hit -a  $prefix\_allReads.fna -d FinalSizeSelected.fna -o Map_ReNameReads.txt -c 95;");
system ("cd $nd; FR-Hit_RenameFinalContigs.pl Map_ReNameReads.txt FinalSizeSelected.fna > $prefix\_FinalContigs.fna;");

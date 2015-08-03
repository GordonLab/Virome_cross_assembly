# Virome_cross_assembly
The cross-assembly consists of two rounds, one for each family individually and the the cross-assembly for all families.

To run the first round of assembly run:
Wrapper_CrossAssembly_Malawi1.pl F3 > Log_Ma_F3.txt

To Run de second run of assembly, run:

Wrapper_CrossAssembly_Malawi2.pl F22 > Log_Ma2_F22.txt


Third party software needed:
cd-hit-est
runAssembly
fr-hit
makeblastdb / blastn 
phrap

Is designed for a cluster environment running in SGE job scheduler.



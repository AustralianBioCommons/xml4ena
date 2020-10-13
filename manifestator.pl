#!/usr/bin/perl
print "Script to manifest files for ENA genome/exon assembly upload" ;
open INPUT, "<manifest_meta_table.txt" || die "Can't read metadata from manifest_meta_table.txt\n$!\n";
@INPUT=<INPUT>;
close INPUT;
# --- manifest_meta_table.txt --- 25/09/2020
#BPA_ID	Primary Accession	Secondary Accession	TCCP_ID	depthmedian
#10001   ERS0000001      SAMEA0000110    10001_AHGVYVBCX2_GAATCTC_S19_DD.fasta.gz    127
#10002   ERS0000011      SAMEA0000111    10002_AHGVYVBCX2_GAGGAC_S21_DD.fasta.gz     88
#10003   ERS5079562      SAMEA0000112    10003_AHGVYVBCX2_GATTCTC_S33_DD.fasta.gz    87

$n=0;
foreach $line (@INPUT) {
	chomp $line;
	@LINE    = split "\t", $line;
    $BPA_ID  = shift  @LINE;
    $Primary = shift  @LINE;
    $Second  = shift  @LINE;
    $TCCP_ID = shift  @LINE;	
    $depthmd = shift  @LINE;
	if ($Second ne "NA") {
		$n++;
		print "\n$n\t$line"; 
		open  SAVE, ">$BPA_ID\.manifest" || die "Can not write manifest to $BPA_ID\.manifest\n$!\n";
		print SAVE "STUDY\t PRJEB00000\n";  ##Update this for your submission
		print SAVE "SAMPLE\t $Second\n";
		print SAVE "ASSEMBLYNAME\t$Primary MarsupialExonCaptKit\n";
		print SAVE "ASSEMBLY_TYPE\tisolate\n";
		print SAVE "COVERAGE\t $depthmd\n";
		print SAVE "PROGRAM\t\"TCCP \(docker: trust1/ubuntu:OMGv001\)\"\n";
		print SAVE "PLATFORM\t illumina\n";
		print SAVE "MINGAPLENGTH\t50\n";
		print SAVE "MOLECULETYPE\t genomic DNA\n";
#		print SAVE "INFO\tDenovo assembly of targeted exons from sequencing library enriched with marsupial exon capture kit.\n"; 
		print SAVE "FASTA\t$TCCP_ID\_DD.fasta.gz\n";
		close SAVE;
	}
};
print "\nDone manifestation\n";
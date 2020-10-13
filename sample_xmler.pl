#!/usr/bin/perl 
#13/10/2020
# SOME FIXED FIELDS WHICH WILL BE SAME ACROSS SAMPLES
$investigationtype     = "phylogenetic study";
$sequencingmethod      = "Illumina SBS, short PE reads";
$bioprojectaccessionid = "PRJEB00000000";     #Registry project online manually prior to generating those XMLs

print "For full list of available checklists refer:    www.ebi.ac.uk/ena/browser/checklists\n";  
print "Using ERC000011 - ENA default sample checklist: www.ebi.ac.uk/ena/browser/api/xml/ERC000011\n";
print "\nEnter full path  to the file metadata file (or enter for metatdata.txt):\n";
$metadatatsv = <STDIN>;
chomp $metadatatsv ;
if ($metadatatsv eq "") {
   $metadatatsv = "metadata.txt";
};

@PATH = split "/", $metadatatsv;
pop @PATH;
$workdir = join "/", @PATH;
chdir $workdir ;
open METADATA, "<$metadatatsv" || die ("\n Error !!! \nCan not read metadata.txt\n$!");
@METADATA = (<METADATA>);
close metadata;
$header   = shift @METADATA ;
chomp $header ;
@header   = split "\t", $header;
$colsnmbr = scalar @header;


$nc=0;
print "\n############ START OF HEADER OF METADATA HAS FOLLOWING COLUMNS ############################\n";
foreach $col (@header) {
  $nc ++;
  print "\n$nc\t$col"; 
  if ($col =~ m/country/gix) {
    $countrycolumn = $nc;
  } elsif ($col =~ m/state|region|state_or_region/gix) {
    $regioncolumn =  $nc;
  } elsif ($col =~ m/collection_date/gix) {
	$coldatecolumn = $nc; 
  };
}
print "\n############ END OF THE HEADER OF METADATA HAS FOLLOWING COLUMNS #########################";
print "\nSelect column number for following identifiers choose from 1 - $colsnmbr:\n";
print "   Sample ID/NAME column: ";
$sampleidcolumn = (<STDIN>);
chomp $sampleidcolumn; 
print "   TAXON_ID column: ";
$taxonidcolumn = (<STDIN>);
chomp $taxonidcolumn;
print "   COMMON_NAME: ";
$comnamecolumn = (<STDIN>);
chomp $comnamecolumn ;
print "   Scientific Name (Genus Species). In case of combining two columns type comma as separator: ";
$sciencenamecol = (<STDIN>);
chomp $sciencenamecol;

## Some defaults for quick tests
if ( $sampleidcolumn == "" ){ 
	 $sampleidcolumn = 1;
};
if ( $taxonidcolumn == "" ){ 
	 $taxonidcolumn  = 8;
};
if ( $comnamecolumn  == "" ){ 
	 $comnamecolumn = 16;
};
if ( $sciencenamecol == "" ){
	 $sciencenamecol = "13,14";
	 $testname = join " ", (split "\t",  $METADATA[0])[12,13];
};
@SNCOL = split ",", $sciencenamecol; 

### Test the first sample mandatory records
@testline = split "\t", $METADATA[0] ;
foreach $tcol (@SNCOL) {
	push @tcolvalue, $testline[$tcol-1];
};
$tsntname = join " ", @tcolvalue;


print "\n############ CHECK THE ASIGNMENT OF MANDATORY RECORDS FOR THE 1st SAMPLE #################\n";
print "Your template choose is: ERC000011\n"; \
print "Sample NAME:\t\t$testline[$sampleidcolumn-1]\n"; 
print "TAXON_ID: \t\t$testline[$taxonidcolumn-1]\n";
print "COMMON_NAME: \t\t$testline[$comnamecolumn-1]\n";
print "SCIENTIFIC NAME: \t$tsntname\n";
if ($countrycolumn ne "") {
  print "COUNTRY: \t\t$testline[$countrycolumn-1]\n";
}else{
	$countrycolumn = 0;
};
if ($regioncolumn ne "") {
  print "REGION: \t\t$testline[$regioncolumn-1]\n";
  }else{
    $regioncolum = 0  ;
};
if ($coldatecolumn ne "") {
  print "Collection Date: \t$testline[$coldatecolumn-1]\n";
}else{
	$coldatecolumn = 0;
};
print "\nCheck 1st sample attributes above and press enter to continue:";
$go = <STDIN>;

mkdir "sample_XMLs" || die ("\n Error !!! \nCan not make folder sample_XMLs \n$!");

## Trimming unasigned colums (nonspecific fields) and subtract 1 from all residual elements
@USEDCOL = sort { $a <=> $b } ($sampleidcolumn, $countrycolumn, $regioncolum,  $coldatecolumn, $taxonidcolumn, $comnamecolumn); # $sciencenamecol ? 
@USEDCOL = grep { $_ != 0 } @USEDCOL; 
@USEDCOL = map { $_ -1   } @USEDCOL;
@hindexes = (0..$#header); 
splice( @hindexes, $_, 1) for (reverse sort @USEDCOL);  ## trimming used columns from hindex 

foreach $samplerow (@METADATA) {
  unless ($samplerow =~ m/^\#/g) {
     chomp $samplerow;
     @colvalue =();
  	 @LINE = split "\t", $samplerow;
     $sample  = $LINE[$sampleidcolumn-1];
     $taxon   = $LINE[$taxonidcolumn-1];
     $comname = $LINE[$comnamecolumn-1];
     $country = $LINE[$countrycolumn-1];
	 $region  = $LINE[$regioncolumn-1];
	 $coldate = $LINE[$coldatecolumn-1];
	 $coldate =~ s/unknown/2020-06-31/gx;   ## no chars allowed in date field . 
	 foreach $col (@SNCOL) {
		   push @colvalue, $LINE[$col-1];
     };
	 $sntname = join " ", @colvalue;

	open SAVEFILE, ">sample_XMLs/$sample\.ena.xml" || die  ("\nCann not write to $sample.ena.xml\n$!\n");
    print SAVEFILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n";
    print SAVEFILE "<SAMPLE_SET> \n";
    print SAVEFILE "  <SAMPLE alias=\"$sample\" center_name=\"Australian National University. BPA/OMG\"> \n";
    print SAVEFILE "    <TITLE>Australian marsupal phylogenetic study. Bioplatforms Australia and Oz Mamammals Genomics.</TITLE> \n";
    print SAVEFILE "    <SAMPLE_NAME> \n";
    print SAVEFILE "      <TAXON_ID> $taxon </TAXON_ID> \n";
    print SAVEFILE "      <SCIENTIFIC_NAME>$sntname</SCIENTIFIC_NAME> \n";
    print SAVEFILE "      <COMMON_NAME>$comname</COMMON_NAME> \n";
    print SAVEFILE "    </SAMPLE_NAME> \n";
    print SAVEFILE "    <SAMPLE_ATTRIBUTES> \n";

## Three key fields (semimandatory)

    print SAVEFILE "         <SAMPLE_ATTRIBUTE> \n";
    print SAVEFILE "             <TAG>bioproject_accession</TAG> \n";
    print SAVEFILE "             <VALUE>$bioprojectaccessionid</VALUE> \n";  ## This has wague doc 
    print SAVEFILE "          </SAMPLE_ATTRIBUTE> \n";

    print SAVEFILE "         <SAMPLE_ATTRIBUTE> \n";
    print SAVEFILE "             <TAG>investigation type</TAG> \n";
    print SAVEFILE "             <VALUE>$investigationtype</VALUE> \n";
    print SAVEFILE "          </SAMPLE_ATTRIBUTE> \n";

	print SAVEFILE "          <SAMPLE_ATTRIBUTE> \n";
    print SAVEFILE "             <TAG>sequencing method</TAG> \n";
    print SAVEFILE "             <VALUE>$sequencingmethod</VALUE> \n";
    print SAVEFILE "          </SAMPLE_ATTRIBUTE> \n";

# Three optional field supposedly have fixed entries (to help with ENA integration ... may be)

	if ($countrycolumn != 0) {
		print SAVEFILE "          <SAMPLE_ATTRIBUTE> \n";
		print SAVEFILE "             <TAG>geographic location (country and/or sea)</TAG>\n";
		print SAVEFILE "             <VALUE>$country</VALUE> \n";
		print SAVEFILE "          </SAMPLE_ATTRIBUTE> \n";
	};

	if ($regioncolumn != 0) {
		print SAVEFILE "          <SAMPLE_ATTRIBUTE>\n";
		print SAVEFILE "            <TAG>geographic location (region and locality)</TAG>\n";
		print SAVEFILE "            <VALUE>$region</VALUE> \n";
		print SAVEFILE "          </SAMPLE_ATTRIBUTE> \n";
	};

	if ($coldatecolumn != 0) {
		print SAVEFILE "          <SAMPLE_ATTRIBUTE>\n";
		print SAVEFILE "            <TAG>collection date</TAG>\n";
		print SAVEFILE "            <VALUE>$coldate</VALUE>\n";
		print SAVEFILE "          </SAMPLE_ATTRIBUTE>\n";
	};

## Stuffing the rest of the header into SAMPLE_ATTRIBUTE  
    foreach $h (@hindexes) {
		print SAVEFILE "          <SAMPLE_ATTRIBUTE>\n";
		print SAVEFILE "            <TAG>$header[$h]</TAG>\n";
		print SAVEFILE "            <VALUE>$LINE[$h]</VALUE>\n";
		print SAVEFILE "          </SAMPLE_ATTRIBUTE>\n";     
    };

	print SAVEFILE "          <SAMPLE_ATTRIBUTE>\n";
	print SAVEFILE "            <TAG>ENA-CHECKLIST</TAG>\n";
	print SAVEFILE "            <VALUE>ERC000011</VALUE>\n";
	print SAVEFILE "          </SAMPLE_ATTRIBUTE>\n";
    print SAVEFILE "    </SAMPLE_ATTRIBUTES> \n";
    print SAVEFILE "  </SAMPLE> \n";
    print SAVEFILE "</SAMPLE_SET> \n";
	close SAVEFILE;
 }
};
### Make submission.xml (Those ENA guys are nuts)
open  SAVEFILE, ">sample_XMLs/submission.xml" || die ("\n!!!Error!!! Problem with writing to sample_XMLs/submission.xml\n$!\n");
print SAVEFILE  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print SAVEFILE  "<SUBMISSION>\n";
print SAVEFILE  "   <ACTIONS>\n";
print SAVEFILE  "      <ACTION>\n";
print SAVEFILE  "         <ADD/>\n";
print SAVEFILE  "      </ACTION>\n";
print SAVEFILE  "   </ACTIONS>\n";
print SAVEFILE  "</SUBMISSION>\n";
close SAVEFILE;

print "\n####################################### DONE ############################################\n";
print "More info: https://ena-docs.readthedocs.io/en/latest/submit/samples/programmatic.html\n";
#print "To upload generated XML files use curl command:\n";
#print "\ncurl -u \'username:password\' -F \"SUBMISSION=@submission.xml\" -F \"SAMPLE=@sample.xml\" \"https://wwwdev.ebi.ac.uk/ena/submit/drop-box/submit/\"";
#print "\n!!!Note you have to change: wwwdev.ebi.ac.uk ---> www.ebi.ac.uk  for the real upload. Otherwise it will live there only for 24hrs.\n"; 

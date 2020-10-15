# xml4ena

## Description

Two helper perl scripts and associated documentation for bulk genome upload to the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home) sequence repository. 

The [Target Capture Cloud Platform (TCCP)](https://hub.docker.com/r/trust1/ubuntu) produces multi-FASTA assembly files containing about 1-3 k sequences: these are technically identical to genome assembly files. 

The diplotype files produced by TCCP require extra effort to upload to a repository as they have long strings of N in hard masked low coverage areas of the assemblies. 

**Note:** the procedure developed below assumes that you have already established [a webin account with ENA](https://www.ebi.ac.uk/ena/submit/sra/#home). Check the official documentation page for this step to [register a submission account]( https://ena-docs.readthedocs.io/en/latest/submit/general-guide/registration.html) 

| Workflow element | GitHub | bio.tools | BioContainers | bioconda |
|-------------|:--------:|:--------:|:--------:|:--------:|
|sample_xmler.pl |[&#9679;](./sample_xmler.pl)||||
|manifestator.pl |[&#9679;](./manifestator.pl)||||

## Required (minimum) inputs/parameters

### Inputs

- Metadata in a single tab delimited metadata.txt file
- Manifest_meta_table.txt

### Parameters

Fix the following variables in the `sample_xmler.pl` script:

    $investigationtype     = "phylogenetic study";
    $sequencingmethod      = "Illumina SBS, short PE reads";
    $bioprojectaccessionid = "PRJEB00000";     #Registry project online manually prior to generating those XMLs

## Third party tools / dependencies

- ENA webin web browser GUI: to register data sets and prepare for programmatic submission
- webin-cli-3.1.0.jar: to upload fasta files

**Note:** the webin-cli-3.1.0 [requires Java 1.8 or newer](https://github.com/enasequence/webin-cli#executable-java-jar)

# Diagram

# Usage

## Summary

Not applicable

## High level resource usage

Not applicable

## Additional notes

Not applicable

# Install

# Tutorials

## Stage 0 Register your new project on ENA webin 

Follow the interactive menu and enter information about your study. This will create a project ID record which will underpin the submitted samples. 

## Stage 1: Prepare BioSample entries [sample_xmler.pl]

BioSample records contain information about your sample and will link this metadata to the project ID sequence file. The following steps are required to run sample_xmler.pl

### 1.1 Collect metadata in single tab delimited metadata.txt file

The metadata file can have an arbitrary number of fields (columns), but there are the following obligatory columns which you have to select interactively with a perl script.

1.	**Sample ID/NAME**  --  should match the beginning of the assembly file name. *I recommend use of the Bioplatforms Australia sample ID here.* 
2.	**TAXON_ID**  -- **note:** this should be the exact species ID from the [NCBI taxonomy database](https://www.ncbi.nlm.nih.gov/taxonomy). Genus or any other than species taxonomy level are not allowed here. 
3.	**Scientific name**  --  genus and species ID could be combined from two metadata columns here. 
4.	**COMMON_NAME**  -- commonly used name for the taxon.

Optional columns will be parsed and coded automatically if you will keep header names like those
     * country
     * state|region|state_or_region
     * collection_date

Here is an example: [metadata.txt](metadata.txt)

### 1.2  Run sample_xmler.pl script to convert meta 

You have to fix the following variables in the script before running (sorry no interface for those yet):

      $investigationtype     = "phylogenetic study";
      $sequencingmethod      = "Illumina SBS, short PE reads";
      $bioprojectaccessionid = "PRJEB00000";     #registered project created manually online prior to generating XMLs

The script should produce a set of XML files ready for upload to ENA.

### 1.3 Prepare submission.xml

This file should have following lines

      <?xml version="1.0" encoding="UTF-8"?>
      <SUBMISSION>
         <ACTIONS>
            <ACTION>
               <ADD/>
            </ACTION>
         </ACTIONS>
      </SUBMISSION>

You can change  <ADD/> to:

      <MODIFY/>   ## For update existing sample
      <HOLD target="TODO: study accession number" HoldUntilDate="TODO: YYYY-MM-DD"/>
      <RELEASE target="TODO: study accession number"/>
      <RECEIPT target="submission alias or accessions"/>
      <KILL target="TODO: object accession number"/>

More options are available [here](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/programmatic.html).

### 1.4 Upload with curl

To upload generated XML files use curl command:\n";

      ncurl -u \'username:password\' -F \"SUBMISSION=@submission.xml\" -F \"SAMPLE=@sample.xml\" \"https://wwwdev.ebi.ac.uk/ena/submit/drop-box/submit/\"";

**Note:**: you have to change: `wwwdev.ebi.ac.uk` ---> `www.ebi.ac.uk`  for the real upload. Otherwise the submission will only be there for 24hrs.

### 1.5 Collect receipts from submission  

You have to compile all receipts generated by BioSample submission into a single table. If receipts are missing you can login to your account and download the sample IDs table manually from there. 

## Stage 2 Submit assembly files [manifestator.pl]

In stage 1 you created database entries for BioSample ID. Now you need to create manifest files for the assemblies using the BioSample IDs with `manifestator.pl`. To upload the assemblies you will require 2 files:

1.	Manifest file: text with sample IDs.	 
2.	FASTA file: for unannotated assemblies (plain multi fasta)

### 2.1 Prepare manifest_meta_table.txt

This is another metadata tab delimited text file with only a few columns. This file may have the following columns:

1.	Bioplatforms Australia sample / library ID
2.	BioSample sample ID
3.	BioSample alias ID
4.	FASTQ file name
5.	Coverage (sequencing depth, from TCCP QC metrics)

Example:

|Bioplatforms sample ID / Bioplatforms library ID |	BioSample ID |	BioSample alias ID | FASTQ file name | Coverage (sequencing depth, from TCCP QC metrics)|
|:--------:|:--------:|:--------:|:-------------------:|:--------:|
|10001 |  ERS0000001   |   SAMEA0000110  |  10001_AHGVYVBCX2_GAATCTC_S19_DD.fasta.gz  |  127|
|10002 |  ERS0000011   |   SAMEA0000111  |  10002_AHGVYVBCX2_GAGGAC_S21_DD.fasta.gz   |  88|
|10003 |  ERS5079562   |   SAMEA0000112  |  10003_AHGVYVBCX2_GATTCTC_S33_DD.fasta.gz  |  87|

### 2.2 run manifestator.pl

This script will take the `manifest_meta_table.txt` table and split it into individual manifests: named by ID provided in the first column of metadata. An example product manifest file (10001.manifest) is shown below: 

      STUDY    PRJEB00000
      SAMPLE   SAMEA0000110
      ASSEMBLYNAME    ERS0000001 MarsupialExonCaptKit
      ASSEMBLY_TYPE   isolate
      COVERAGE         127
      PROGRAM "TCCP (docker: trust1/ubuntu:OMGv001)"
      PLATFORM         illumina
      MINGAPLENGTH    50
      MOLECULETYPE     genomic DNA
      FASTA   10001_AHGVYVBCX2_GAATCTC_S19_DD.fasta.gz

Where:

`PRJEB00000` is the project ID created when you manually register a data set using ENA webin. 
`SAMEA0000110` is a sample ID that could be taken either from an XML submission receipt (i.e. the log file) or downloaded from the ENA BioSample summary page for the BioProject. **Hint:** if you are missing the sample IDs you can rerun the xml submission (see step # 1.3 ) with a modified “submission.xml”          
        
      <ACTION>
         <VALIDATE/>
      </ACTION>

### 2.3 Submit sequence data with webin-cli-3.1.0.jar

To upload fasta files you will need to obtain the submission program `webin-cli-3.1.0.jar` (or the latest version) from the [ENA GitHub](https://github.com/enasequence/webin-cli/releases)

Here is the shell command to cycle across manifests and samples:

      for file in *.manifest
      do echo $file && java -jar /usr/local/bin/webin-cli-3.1.0.jar  \
         -userName Webin-Username \
         -password='somepasswordhere' \
         -context=genome \
         -manifest=/data/local/tmp/$file \
         -inputdir=/data/local/tmp \
         -submit 
      done


### 2.4  Collect fasta data id from 

Check that the receipts for line pattern have the value `success="true"`. Keep the receipts in case you need to add further work or update the existing assembly files. 

Here is an example of a receipt file:

        % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Download  Upload   Total   Spent    Left  Speed
      100  7322  100   542  100  6780    345   4323  0:00:01  0:00:01 --:--:--  4666
      <?xml version="1.0" encoding="UTF-8"?>
      <?xml-stylesheet type="text/xsl" href="receipt.xsl"?>
      <RECEIPT receiptDate="2020-09-25T00:38:36.465+01:00" submissionFile="submission.xml" success="true">
         <SAMPLE accession="ERS0000001" alias="10001" status="PRIVATE">
               <EXT_ID accession="SAMEA0000110" type="biosample"/>
         </SAMPLE>
         <SUBMISSION accession="" alias="SUBMISSION-25-09-2020-00:38:36:347"/>
         <MESSAGES>
               <INFO>Submission has been committed.</INFO>
         </MESSAGES>
         <ACTIONS>MODIFY</ACTIONS>
      </RECEIPT>

# Help / FAQ / Troubleshooting

- [readthedocs: ENA register a submission account](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/registration.html)
- [readthedocs: ENA programmatic submission guide](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/programmatic.html)

# [Licence](https://github.com/AustralianBioCommons/xml4ena/blob/master/LICENSE)

# Acknowledgements / citations / credits

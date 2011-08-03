# data-ingestion-pipeline

The DIP script takes a VoID URL as input, looks for the dataDump URL, gets the dataDump, and finally imports it into Fuseki's RDF store.


## Setup
Change the BASEDIR, DATASET, PORT values in dip.sh to your own:


## Usage
### Importing dataDumps into RDF store via VoID
    dip.sh http://example.org/void.ttl


## SPARQL Graph names
Currently considering ways to name graphs in SPARQL Updates for the data in dataDumps.

Let's look at some cases:

1. Single RDF file (http://example.org/datadump.ttl)
2. Multiple RDF files (http://example.org/datadump.zip)
    * 2.1. RDF files in root directory only (http://example.org/datadump.zip contains)
        * /d0.ttl
        * /d1.ttl
    * 2.2. RDF files in root and/or sub-directories (http://example.org/datadump.zip contains)
        * /d0.ttl
        * /d1.ttl
        * /0/d0.ttl
        * /0/d1.ttl
        * /0/d2.ttl
        * /1/d0.ttl
        * /2/d1.ttl

The simplest approach is to use the datadump URL as the graph name. Anything else would be custom and subject to arbitrary rules for building a graph name.

For instance, in case 2.2, we have a scenario with multiple directories with multiple files. Some possibilities are:

1. each file name as its own graph name
2. each directory name as the graph name
3. each directory name and the file name as the graph name

If we don't preserve the original dataDump URL in any form, we are subject to run into a situation where graph names get overridden as different dataDump files may have the same path and file structure.

Hence, it is probably a good idea to retain the datadump URL in the graph name. It will also help knowing where the data was retrieved from. Otherwise, we need to have the following triples in each graph to make that explicit e.g.,

    <http://example.org/datadump.zip/0/d1.ttl> a void:dataSet ;
        void:dataDump <http://example.org/datadump.zip> .

Therefore, the simplest conclusion here is to use the dataDump URL as the graph name. What are some of the issues with this approach?

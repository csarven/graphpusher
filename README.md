# data-ingestion-pipeline

## Overview

Data Ingestion Pipeline (DIP) is a tool to rebuild an RDF store based on the information in a VoID file.

The DIP script takes a VoID URL as input from command-line, looks for the dataDump URL, gets the dataDump, and finally imports it into Fuseki's RDF store using one of the graph name methods.

This script is tested and is functional under Debian/Ubuntu. Feedback is appreciated from other OS users.


## Requirements
* [Ruby](http://ruby-lang.org/) (required gems: rubygems, net/http, net/https, uri, fileutils, filemagic)
* tar, gzip, unzip, 7za, rar
* [Raptor RDF Syntax Library](http://librdf.org/raptor/), and [rapper](http://librdf.org/raptor/rapper.html) RDF parser utility program
* [Fuseki](http://openjena.org/wiki/Fuseki) SPARQL server
* [TDB](http://openjena.org/wiki/TDB) RDF store (optional: where tdbAssembler setting is used)


## Configuration
* basedir : Location to store the dumps
* dataset : Dataset name for the store
* tdbAssembler : TDB assembler file
* graphNameCase : Graph name method for SPARQL
* graphNameBase : Base URL for graph names
* port : Port number for Fuseki
* os : Operating System name to determine new line types


## Usage
Importing dataDumps into RDF store via VoID file:

    Usage: dip.rb voidurl
    Example: dip.rb http://example.org/void.ttl


## SPARQL Graph names
A graph name for the SPARQL Endpoint uses one of the following (from highest to lowest priority) by setting the graphNameCase:

* sd:name (default)
* dataset
* dataDump
* filename

By default, if sd:name in VoID is present, it will be used for SPARQL graph name, otherwise, dataset URI will be used. If dataDump or filename is set, they will be used instead of dataset.

When filename is set for the graph name case, the base URL value (graphNameBase) for graph name is used in the SPARQL Endpoint.


## ToDo
Ability to use datadump files from the local network drive.

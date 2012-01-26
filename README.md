# GraphPusher

## Overview

GraphPusher is a tool to rebuild an RDF store based on the information in a VoID file.

The GraphPusher tool takes a VoID URL as input from command-line, retrieves the VoID file, looks for the <code>void:dataDump</code> property values in the VoID description, HTTP GETs them, and finally imports them in to an RDF store using one of the graph name methods. The graph name method is defined as part of GraphPusher's configuration.

This script is tested and is functional under Debian/Ubuntu. Feedback is appreciated from other OS users.

## Requirements
* [Ruby](http://ruby-lang.org/) (required gems: rubygems, net/http, net/https, uri, fileutils, filemagic)
* tar, gzip, unzip, 7za, rar
* [Raptor RDF Syntax Library](http://librdf.org/raptor/), and [rapper](http://librdf.org/raptor/rapper.html) RDF parser utility program
* [Fuseki](http://openjena.org/wiki/Fuseki)'s SOH script (included in this package)
* [TDB](http://openjena.org/wiki/TDB) RDF store (optional: where tdbAssembler setting is used)

## Configuration
* basedir : Location to store the dumps
* dataset : Dataset name for the store
* tdbAssembler : TDB assembler file
* graphNameMethod : Graph name method for SPARQL
* graphNameBase : Base URL for graph names
* os : Operating System name to determine new line types and directory separators


## Usage
Importing dataDumps into RDF store via VoID file:

    Usage: ruby graphpusher.rb VOIDURL [OPTIONS]
    Examples: ruby GraphPusher.rb http://example.org/void.ttl --assembler=/usr/lib/fuseki/tdb2_slave.ttl
              ruby GraphPusher.rb http://example.org/void.ttl --dataset=http://localhost:3030/dataset/data

## SPARQL Graph names
A graph name for the SPARQL Endpoint uses one of the following (from highest to lowest priority) by setting the graphNameMethod:

* dataset (default)
* dataDump
* filename

By default, if sd:name in VoID is present, it will be used for SPARQL graph name, otherwise, dataset URI will be used. If dataDump or filename is set, they will be used instead of dataset. When filename is set for the graph name case, the base URL value (graphNameBase) for graph name is used in the SPARQL Endpoint.


## ToDo
* Ability to use datadump files from the local network drive
* Retrieval of the VoID graph from a SPARQL endpoint


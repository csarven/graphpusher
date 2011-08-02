# data-ingestion-pipeline

The DIP script takes a VoID URL as input, looks for the dataDump URL, gets the dataDump, and finally imports it into Fuseki's RDF store.


## Setup
Change the BASEDIR, DATASET, PORT values in dip.sh to your own:


## Usage
### Importing dataDumps into RDF store via VoID
	dip.sh http://example.org/void.ttl

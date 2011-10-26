# Config
# Location to store the dumps
$basedir='/var/www/test'

# graphName to use in SPARQL Endpoint can be one of (from highest to lowest priority):
# sd:name
# dataset
# dataDump
# filename

# By default, if sd:name in VoID is present, it will be used for SPARQL graph name, otherwise, dataset URI will be used. If dataDump or filename is set, they will be used instead of dataset.
$graphNameCase='dataset'

# Base URL for graph name to be used in SPARQL Endpoint. When $graphNameCase='filename', this is used.
$graphNameBase='http://example.org/graph/'

#TODO: dataDumps are either local or remote (default)
#$remoteDataDumps = true

# Port number in which we are running the Fuseki server. If tdbAssembler is set, this is not used.
$port='3939'

# Operating system
$os = 'linux'

# Sets new line character based on Operating System
case $os
    when "linux"
        $ds = "/"
        $nl = "\n"
    else
        $ds = "\\"
        $nl = "\r\n"
end

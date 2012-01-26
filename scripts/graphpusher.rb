# GraphPusher
#    Retrieves and imports data in RDF format into a graph store
#    based on the metadata in a VoID file

#    Homepage: https://github.com/csarven/GraphPusher
#    Author:   http://csarven.ca/#i
#    License:  http://www.apache.org/licenses/LICENSE-2.0

require 'utils.rb'

if ARGV.length == 0 || ARGV[0] == "-h" || ARGV[0] == "--h" || ARGV[0] == "-help" || ARGV[0] == "--help"
    puts "GraphPusher - Rebuild an RDF store from VoID"
    puts "    Homepage: https://github.com/csarven/GraphPusher"
    puts "    Author:   http://csarven.ca/#i"
    puts "    License:  http://www.apache.org/licenses/LICENSE-2.0"
    puts ""
    puts "    ARGUMENTS"
    puts "        VOIDURL [OPTIONS]"
    puts ""
    puts "    VOIDURL"
    puts "        A well-formed VoID file"
    puts ""
    puts "    OPTIONS"
    puts "        --assembler {tdbAssembler}"
    puts "        --dataset {datasetURI}"
    puts ""
    puts "    EXAMPLES"
    puts "        ruby GraphPusher.rb http://example.org/void.ttl --assembler=/usr/lib/fuseki/tdb2_slave.ttl"
    puts "        ruby GraphPusher.rb http://example.org/void.ttl --dataset=http://localhost:3030/dataset/data"
    puts ""
    puts "    NOTES"
    puts "        See also config.rb for configuration settings"

    exit
end

ARGV.each do |a|
    if a =~ /--assembler=/
        $tdbAssemblerSlave = a.split(/--assembler=/)[1]
    else
        if a =~ /--dataset=/
            $datasetURI = a.split(/--dataset=/)[1]
        end
    end
end

$voidurl = ARGV[0]

$voidurlsafe = $voidurl.gsub(/[^a-zA-Z0-9\._-]/, '_')

$voiddir=$basedir + $ds + $voidurlsafe

if !FileTest::directory?($voiddir)
    Dir::mkdir($voiddir)
    puts "Made directory: " + $voiddir
end
puts "Directory " + $voiddir + " already exists."

$voidfile=$voiddir + $ds + "void.nt"
puts $voidfile

puts "Attempting to get " + $voidurl + " and copy over to " + $voidfile
#Try to refactor this with indexTriples
%x[rapper -g #{$voidurl} -o ntriples > #{$voidfile}]

puts "Analyzing " + $voidfile

ddd = {}
triples = indexTriples($voidfile)

dataDumps = getTriples(triples, nil, "<http://rdfs.org/ns/void#dataDump>", nil)

if dataDumps.length > 0
    dataDumps.each do |a, b|
        datadumpurl = nil

        b.each do |x, y|
            datadumpurl = y
            ddd[datadumpurl] ||= {}
        end

        sdGraphs = getTriples(triples, nil, "<http://www.w3.org/ns/sparql-service-description#graph>", a)

        if sdGraphs.length > 0
            sdGraphs.each do |c, d|
                sdNames = getTriples(triples, c, "<http://www.w3.org/ns/sparql-service-description#name>", nil)
                if sdNames.length > 0
                    sdNames.each do |x, y|
                        y.each do |w, u|
                            ddd[datadumpurl][u] ||= []
                        end
                    end
                end
                #An else can go here to make sure there really is a name
            end
        else
            puts "\nNo sd:graph found. Falling back to #{$graphNameMethod} URL for graph names."
            case $graphNameMethod;
                when 'filename'
                    ddd[datadumpurl][['___filename___']] ||= []
                when 'dataDump'
                    ddd[datadumpurl][datadumpurl] ||= []
                else 'dataset'
                    ddd[datadumpurl][[a]] ||= []
            end
        end
    end
end

# ddd[datadumpurl][graphurl]
puts "\ndatadumps to be imported (datadumpurl => graphurl):\n"
p ddd

if ddd.length > 0
    ddd.each do |i, j|
        i.each do |ddu, b|
            ddu.gsub!(/[\<\>]/, '')
            datadumpdirectorysafe = ddu.gsub(/[^a-zA-Z0-9\._-]/, '_')

            datadumpdirectory = $voiddir + $ds + datadumpdirectorysafe + "-x" + $ds
#            datadumpdirectory.strip!

            datadumpfilesafe = ddu.gsub(/.*\/(.*)/, '\1')
            datadumpfile = $voiddir + $ds + datadumpdirectorysafe

            target = datadumpdirectory + datadumpfilesafe

            response = getURL(ddu)

            file = File.new(datadumpfile, "w+")
            file.write(response.body)
            file.close

            compressedFile = handleFileType(datadumpfile)

            # If the datadumpfile is not compressed, move it into the datadump directory. Otherwise, the contents of the compressed file is already there
            if !compressedFile
                FileUtils.mv(datadumpfile, target)
            end

            importRDF(datadumpdirectory, j)

            # If the datadumpfile was compressed, move it into its own directory once everthing is done
            if compressedFile
                FileUtils.mv(datadumpfile, target)
            end
        end
    end
end

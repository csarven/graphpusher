# SMCS: Sarven's Magical Collection of Scripts for DIP: Data Ingestion Pipeline
# https://github.com/data-gov-ie/data-ingestion-pipeline

# Usage: dip.rb voidurl e.g., ruby dip.rb http://example.org/void.ttl

# Use config.rb for configuration settings.

require 'utils.rb'

if ARGV.length == 0 || ARGV.length > 1 || ARGV[0] == "-h" || ARGV[0] == "--h" || ARGV[0] == "-help" || ARGV[0] == "--help"
    puts "Usage: dip.rb voidurl"
    puts "       Example: dip.rb http://example.org/void.ttl"
    exit
end

$voidurl = ARGV[0]
$voidurlsafe = $voidurl.gsub(/[^a-zA-Z0-9\._-]/, '_')

$voiddir=$basedir + $ds + $voidurlsafe

if !FileTest::directory?($voiddir)
    Dir::mkdir($voiddir)
    puts "XXX: Made directory: " + $voiddir + $nl
end
puts "XXX: Directory " + $voiddir + " already exists." + $nl

$voidfile=$voiddir + $ds + "void.nt"
puts $voidfile

puts "XXX: Attempting to get " + $voidurl + " and copy over to " + $voidfile + $nl
%x[rapper -g #{$voidurl} -o ntriples > #{$voidfile}]

puts "XXX: Analyzing " + $voidfile + $nl

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
            puts "\nXXX: No sd:graph found. Falling back to #{$graphNameCase} URL for graph names."
            case $graphNameCase;
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
puts "\nXXX: datadumps to be imported (datadumpurl => graphurl):\n"
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

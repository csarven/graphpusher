# SMCS: Sarven's Magical Collection of Scripts for DIP: Data Ingestion Pipeline
# https://github.com/data-gov-ie/data-ingestion-pipeline

# Usage: dip.rb voidurl e.g., ruby dip.rb http://example.org/void.ttl

# Config
# Location to store the dumps
$basedir='/var/www/test'

# Dataset name that is used in Fuseki where we import our data
$dataset='dataset'

# TDB Assembler file
# Set to 'false' if prefer to use Fuseki's SOH script for SPARQL 1.1 Graph Store HTTP Protocol
$tdbAssembler='/usr/lib/fuseki/tdb2_dataset.ttl'
#$tdbAssembler = false

# graphName to use in SPARQL Endpoint can be one of (from highest to lowest priority):
# sd:name
# dataset
# dataDump
# TODO: filename

# By default, if sd:name in VoID is present, it will be used, otherwise, dataset URI will be used. If dataDump or filename is set, they will be used instead of dataset.
$graphName='dataset'

#TODO: dataDumps are either local or remote (default)
#$remoteDataDumps = true

# Port number in which we are running the Fuseki server. If tdbAssembler is set, this is not used.
$port='3333'

# Operating system
$os = 'nix'


# WARNING: Do not touch below this line unless you speak at 0.91 Timbles or more.

case $os
    when "nix"
        $ds = "/"
        $nl = "\n"
    else
        $ds = "\\"
        $nl = "\r\n"
end

require 'rubygems'
require "net/http"
require "net/https"
require 'uri'
require 'fileutils'
require 'filemagic'

def getURL(uri_str, limit = 10)
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    response = Net::HTTP.get_response(URI.parse(uri_str))
    case response
        when Net::HTTPSuccess     then response
        when Net::HTTPRedirection then getURL(response['location'], limit - 1)
        else
           response.error!
    end
end


def handleFileType(datadumpfile)
    compressedFile = true

    fm = FileMagic.new
    filetype = fm.file(datadumpfile)

    target = datadumpfile + "-x" + $ds

    %x[mkdir #{target}]

    case filetype;
        when /gzip compressed.*/
            puts %x[tar zxvf #{datadumpfile} -C #{target} --overwrite]
        when /POSIX tar.*/
            puts %x[tar xvf #{datadumpfile} -C #{target} --overwrite]
        when /bzip2 compressed.*/
            puts %x[tar jxvf #{datadumpfile} -C #{target} --overwrite]
        when /Zip archive.*/
            puts %x[unzip -o #{datadumpfile} -d #{target}]
        when /7-zip archive.*/
            puts %x[7za x -y #{datadumpfile} -o#{target}]
        when /RAR archive.*/
            puts %x[rar -o+ x #{datadumpfile} #{target}]

        else
            puts datadumpfile + " is not a compressed file."
            compressedFile = false
    end

    fm.close

    return compressedFile
end


def getTriples(index, subjects = nil, properties = nil, objects = nil)
    triples = {}

    if (!subjects.nil? && !subjects.kind_of?(Array))
        subjects = [subjects]
    end

    if (!properties.nil? && !properties.kind_of?(Array))
        properties = [properties]
    end

    if (!objects.nil? && !objects.kind_of?(Array))
        objects = [objects]
    end

    index.each do |s, po|
        s_candidate = nil;

        if (subjects.nil? || subjects.include?(s))
            s_candidate = s;

            po.each do |p, o|
                p_candidate = nil;

                if (properties.nil? || properties.include?(p))
                    p_candidate = p;

                    o.each do |o_key|
                        o_candidate = nil

                        if (objects.nil? || objects.include?(o_key))
                            o_candidate = o_key;

                            triples[s_candidate] ||= {}
                            triples[s_candidate][p_candidate] ||= []
                            triples[s_candidate][p_candidate] << o_candidate
                        end
                    end
                end
            end
        end
    end

    return triples
end


def importRDF (target, j)
    Dir.foreach(target) do |f|
        next if f == '.' || f == '..'

        file = target+f

        if File.directory?(file)
            importRDF(file+$ds, j)
        else
            graphName = $voidurl
            if j.length > 0
                j.each do |x, y|
                    graphName = x[0].gsub(/[\<\>]/, '')
                end
            end

            case file;
                when /\.tar\.gz$/,
                     /\.tar$/,
                     /\.gz$/,
                     /\.7z$/,
                     /\.rar$/,
                     /\.bz2$/

                when /\.ttl$/, /\.turtle$/,
                     /\.rdf$/, /\.xml$/, /\.owl$/,
                     /\.nt$/, /\.ntriples/,
                     /\.n3/
                    if $tdbAssembler != false
#puts "\nRunning task: java tdb.tdbloader --desc #{$tdbAssembler} --graph #{graphName} #{file}"
                        puts %x[java tdb.tdbloader --desc #{$tdbAssembler} --graph #{graphName} #{file}]
                    else
                        puts %x[/usr/lib/fuseki/./s-post --verbose http://localhost:#{$port}/#{$dataset}/data #{graphName} #{file}]
                    end
                else
#puts "\nrapper -g #{file} -o turtle > #{file}.ttl"
                    puts %x[rapper -g #{file} -o turtle > #{file}.ttl]
                    if $tdbAssembler != false
#puts "\njava tdb.tdbloader --desc #{$tdbAssembler} --graph #{graphName} #{file}.ttl"
                        puts %x[java tdb.tdbloader --desc #{$tdbAssembler} --graph #{graphName} #{file}.ttl]
                    else
                        puts %x[/usr/lib/fuseki/./s-post --verbose http://localhost:#{$port}/#{$dataset}/data #{graphName} #{file}.ttl]
                    end
                    File.delete(file + ".ttl")
            end
        end
    end
end


if ARGV.length == 0 || ARGV.length > 1 || ARGV[0] == "-h" || ARGV[0] == "--h" || ARGV[0] == "-help" || ARGV[0] == "--help"
    puts "Usage: dip.rb voidurl"
    puts "       example: dip.rb http://example.org/void.ttl"
    exit
end

$voidurl = ARGV[0]
$voidurlsafe = $voidurl.gsub(/[^a-zA-Z0-9\._-]/, '_')

$voiddir=$basedir + $ds + $voidurlsafe

if !FileTest::directory?($voiddir)
    Dir::mkdir($voiddir)
    puts "Made directory: " + $voiddir + $nl
end
puts "Directory " + $voiddir + " already exists." + $nl

$voidfile=$voiddir + $ds + "void.nt"
puts $voidfile

puts "Attempting to get " + $voidurl + " and copy over to " + $voidfile + $nl
%x[rapper -g #{$voidurl} -o ntriples > #{$voidfile}]

puts "Analyzing " + $voidfile + $nl

ddd = {}
triples = {}

file = File.new($voidfile, "r")
while (line = file.gets)
    l = Array.new(line.split(/([^ ]*) ([^ ]*) ([^\>]*[\>]?) (\.)(.*)/))
    s = l[1]
    p = l[2]
    o = l[3]

    triples[s] ||= {} # Create a sub-hash unless it already exists
    triples[s][p] ||= []
    triples[s][p] << o
end

dataDumps = getTriples(triples, nil, "<http://rdfs.org/ns/void#dataDump>", nil)

if dataDumps.length > 0
    dataDumps.each do |a, b|
        datadumpurl = nil

        b.each do |x, y|
            datadumpurl = y
            ddd[datadumpurl] ||= {}
        end

#XXX: Revisit. Going from sd:graph to sd:name is probably unnecessary as they both usually have the same object value. 
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
            case $graphName;
                when 'filename'
                when 'dataDump'
                    ddd[datadumpurl][datadumpurl] ||= []
                else 'dataset'
                    ddd[datadumpurl][[a]] ||= []
            end
        end
    end
end

if ddd.length > 0
    ddd.each do |i, j|
        i.each do |ddu, b|
            ddu.gsub!(/[\<\>]/, '')
            datadumpfilesafe = ddu.gsub(/[^a-zA-Z0-9\._-]/, '_')

            datadumpfile = $voiddir + $ds + datadumpfilesafe
            datadumpfile.strip!

            response = getURL(ddu)

            file = File.new(datadumpfile, "w+")
            file.write(response.body)
            file.close

            compressedFile = handleFileType(datadumpfile)

            target = datadumpfile + "-x" + $ds

            if !compressedFile
                FileUtils.mv(datadumpfile, target)
            end

            importRDF(target, j)

            if compressedFile
                FileUtils.mv(datadumpfile, target)
            end
        end
    end
end

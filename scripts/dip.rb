# SMCS: Sarven's Magical Collection of Scripts for DIP: Data Ingestion Pipeline
# Usage: dip.rb voidurl e.g., dip.rb http://example.org/void.ttl
# Make sure that uncompress.sh is in the same directory as this script.

# Config
# Location to store the dumps
basedir='/var/www/data-gov.ie/data'
# Dataset name that is used in Fuseki where we import our data
dataset='dataset'
# Port number in which we are running the Fuseki server
port='3131'
# Operating system
os = 'nix'

case os
    when "nix"
        ds = "\/"
        nl = "\n"
    else
        ds = "\\"
        nl = "\r\n"
end

require "net/http"
require "net/https"
require 'uri'
require 'fileutils'
require 'rubygems'
require 'filemagic'
require 'zlib'

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

if ARGV.length == 0 || ARGV.length > 1 || ARGV[0] == "-h" || ARGV[0] == "--h" || ARGV[0] == "-help" || ARGV[0] == "--help"
    puts "Usage: dip.rb voidurl"
    puts "       example: dip.rb http://example.org/void.ttl"
    exit
end

voidurl = ARGV[0]
voidurlsafe = voidurl.gsub(/[^a-zA-Z0-9\._-]/, '_')
#puts voidurlsafe

voiddir=basedir + ds + voidurlsafe

if !FileTest::directory?(voiddir)
    Dir::mkdir(voiddir)
    puts "Made directory: " + voiddir + nl
end
puts "Directory " + voiddir + " already exists." + nl

voidfile=voiddir + ds + "void.nt"
#puts voidfile

puts "Attempting to get " + voidurl + " and copy over to " + voidfile + nl
%x[rapper -g #{voidurl} -o ntriples > #{voidfile}]

puts "Grepping " + voidfile + nl

ddu = Array.new
file = File.new(voidfile, "r")
while (line = file.gets)
    if /[^ ]* <http:\/\/rdfs\.org\/ns\/void#dataDump> [^ ]* \./ =~ line
        ddu.push(line.gsub(/([^ ]*) \<http:\/\/rdfs\.org\/ns\/void#dataDump\> \<?([^ >]*)\>? \./, '\2'))
    end
end
file.close


ddu.each do |datadumpurl|
    datadumpurl.strip!
    datadumpfilesafe = datadumpurl.gsub(/[^a-zA-Z0-9\._-]/, '_')

    datadumpfile = voiddir + ds + datadumpfilesafe
    response = getURL(datadumpurl)
    if !response.body.empty?
        puts "Copying " + datadumpurl + " to " + datadumpfile
        file = File.new(datadumpfile, "w+")
        file.write(response.body)
        file.close
    end
end

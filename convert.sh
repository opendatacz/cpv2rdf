#!/bin/bash

set -e

# Check if all dependencies are satisfied
for command in "arq" "curl" "rapper" "saxon" "unzip"
do
  command -v $command >/dev/null 2>&1 || { echo >&2 "$command is missing. Aborting execution."; exit; }
done

# Cleanup
if [ -d "temp" ]; then
  rm -r temp
fi

echo "\n%% Downloading CPV codes..."
curl -O http://simap.europa.eu/news/new-cpv/cpv_2008_xml.zip

echo "\n%% Unzipping..."
unzip -d temp cpv_2008_xml.zip
rm cpv_2008_xml.zip

echo "\n%% Executing XSL transformations..."
saxon -s:temp/cpv_2008.xml -xsl:cpv2rdf.xsl
saxon -s:temp/code_cpv_suppl_2008.xml -xsl:cpv2rdf.xsl

echo "\n%% Converting data to Turtle..."
rapper -i rdfxml -o turtle temp/cpv-2008.xml > temp/cpv-2008.ttl
rapper -i rdfxml -o turtle temp/cpv-2008-supplement.xml > temp/cpv-2008-supplement.ttl
rapper -i rdfxml -o turtle temp/cpv-2008-metadata.xml > temp/cpv-2008-metadata.ttl

echo "\n%% Generating additional data..."
arq --data temp/cpv-2008.ttl --query queries/add_skos_narrowerTransitive.rq > temp/skos_narrowerTransitive_links.ttl

echo "\n%% Merging data..."
cat temp/cpv-2008.ttl temp/cpv-2008-supplement.ttl temp/skos_narrowerTransitive_links.ttl > temp/whole-cpv-2008.ttl

echo "\n%% Calculating data statistics..."
arq --data temp/whole-cpv-2008.ttl --query queries/generateVoid.rq > temp/void.ttl

echo "\n%% Merging metadata..."
cat temp/cpv-2008-metadata.ttl temp/void.ttl > temp/whole-cpv-2008-metadata.ttl

test -d "output" || mkdir output

echo "\n%% Reserializing..."
rapper -i turtle -o turtle temp/whole-cpv-2008.ttl > output/cpv-2008.ttl
rapper -i turtle -o turtle temp/whole-cpv-2008-metadata.ttl > output/cpv-2008-metadata.ttl

# Cleanup
rm -r temp

echo "\n%% Converted CPV is in the 'output' directory"

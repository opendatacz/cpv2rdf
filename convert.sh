#!/bin/bash

set -e

notify () {
  echo -e "\n$1\n"
}

# Check if all dependencies are satisfied
for command in "arq" "curl" "rapper" "saxon" "unzip"
do
  command -v $command >/dev/null 2>&1 || { echo >&2 "$command is missing. Aborting execution."; exit; }
done

# Cleanup
if [ -d "temp" ]; then
  rm -r temp
fi

notify "Downloading CPV codes..."
curl -O http://simap.europa.eu/news/new-cpv/cpv_2008_xml.zip

notify "Unzipping..."
unzip -d temp cpv_2008_xml.zip
rm cpv_2008_xml.zip

notify "Executing XSL transformations..."
saxon -s:temp/cpv_2008.xml -xsl:cpv2rdf.xsl
saxon -s:temp/code_cpv_suppl_2008.xml -xsl:cpv2rdf.xsl

notify "Converting data to Turtle..."
rapper -i rdfxml -o turtle temp/cpv-2008.xml > temp/cpv-2008.ttl
rapper -i rdfxml -o turtle temp/cpv-2008-supplement.xml > temp/cpv-2008-supplement.ttl
rapper -i rdfxml -o turtle temp/cpv-2008-metadata.xml > temp/cpv-2008-metadata.ttl

notify "Generating additional data..."
arq --data temp/cpv-2008.ttl --query queries/add_skos_narrowerTransitive.rq > temp/skos_narrowerTransitive_links.ttl
arq --data temp/cpv-2008.ttl --query queries/add_skos_hasTopConcept.rq > temp/skos_hasTopConcept_links.ttl
arq --data temp/cpv-2008-supplement.ttl --query queries/add_skos_hasTopConcept.rq \
  > temp/skos_hasTopConcept_links_supplement.ttl

notify "Merging data..."
cat temp/cpv-2008.ttl temp/cpv-2008-supplement.ttl \
  temp/skos_narrowerTransitive_links.ttl \
  temp/skos_hasTopConcept_links.ttl temp/skos_hasTopConcept_links_supplement.ttl \
  > temp/whole-cpv-2008.ttl

notify "Calculating data statistics..."
arq --data temp/whole-cpv-2008.ttl --query queries/generateVoid.rq > temp/void.ttl

notify "Merging metadata..."
cat temp/cpv-2008-metadata.ttl temp/void.ttl > temp/whole-cpv-2008-metadata.ttl

test -d "output" || mkdir output

notify "Reserializing..."
rapper -i turtle -o turtle temp/whole-cpv-2008.ttl > output/cpv-2008.ttl
rapper -i turtle -o turtle temp/whole-cpv-2008-metadata.ttl > output/cpv-2008-metadata.ttl

# Cleanup
rm -r temp

notify "Converted CPV is in the 'output' directory"

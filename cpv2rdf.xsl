<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:void="http://rdfs.org/ns/void#"
    version="2.0">
    
    <xsl:param name="namespace" select="'http://ld.opendata.cz/resource/'"/>
    <xsl:variable name="cpvNamespace" select="concat($namespace, 'cpv-2008/')"/>
    <xsl:variable name="cpvScheme" select="concat($namespace, 'concept-scheme/', 'cpv-2008')"/>
    <xsl:variable name="cpvMetadataNamespace" select="concat($namespace, 'dataset/cpv-2008')"/>
    
    <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
    
    <xsl:template match="CPV_CODE">
        <xsl:call-template name="generateConceptScheme">
            <xsl:with-param name="filename">cpv-2008</xsl:with-param>
            <xsl:with-param name="title">Common Procurement Vocabulary 2008</xsl:with-param>
            <xsl:with-param name="schemeNs" select="$cpvScheme"/>
        </xsl:call-template>
        <xsl:call-template name="generateMetadata"/>
    </xsl:template>
    
    <xsl:template match="CPV_SUPPLEMENT">
        <xsl:call-template name="generateConceptScheme">
            <xsl:with-param name="filename">cpv-2008-supplement</xsl:with-param>
            <xsl:with-param name="title">Common Procurement Vocabulary 2008 Supplementary Codes</xsl:with-param>
            <xsl:with-param name="schemeNs" select="concat($namespace, 'concept-scheme/', 'cpv-2008-supplement')"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="generateConceptScheme">
        <xsl:param name="filename"/>
        <xsl:param name="title"/>
        <xsl:param name="schemeNs"/>
        <xsl:result-document href="temp/{$filename}.xml">
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#">
              <skos:ConceptScheme rdf:about="{$schemeNs}">
                  <dcterms:title xml:lang="en"><xsl:value-of select="$title"/></dcterms:title>
                  <dcterms:created rdf:datatype="http://www.w3.org/2001/XMLSchema#date">2008-01-01</dcterms:created>
              </skos:ConceptScheme>
              <xsl:apply-templates>
                  <xsl:with-param name="schemeNs" select="$schemeNs"/>
              </xsl:apply-templates>
            </rdf:RDF>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="generateMetadata">
        <xsl:result-document href="temp/cpv-2008-metadata.xml">
            <rdf:RDF xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:void="http://rdfs.org/ns/void#">
                <void:Dataset rdf:about="{$cpvMetadataNamespace}">
                    <rdf:type rdf:resource="http://www.w3.org/ns/prov#Entity"/>
                    <dcterms:source rdf:resource="http://simap.europa.eu/news/new-cpv/cpv_2008_xml.zip"/>
                    <dcterms:title xml:lang="en">Common Procurement Vocabulary 2008</dcterms:title>
                    <dcterms:description xml:lang="en">Common Procurement Vocabulary 2008 converted to RDF</dcterms:description>
                    <dcterms:modified rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                        <xsl:value-of select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                    </dcterms:modified>
                    <dcterms:publisher rdf:resource="http://opendata.cz"/>
                    <dcterms:license rdf:resource="http://opendatacommons.org/licenses/pddl/1-0"/>
                    <void:rootResource rdf:resource="{$cpvScheme}"/>
                    <void:exampleResource rdf:resource="{concat($cpvNamespace, 'concept/', '18317000')}"/>
                </void:Dataset>
            </rdf:RDF>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="CPV | SUPPL">
        <xsl:param name="schemeNs"/>
        
        <!-- Remove check digit -->
        <xsl:variable name="code" select="tokenize(@CODE, '-')[1]"/>
        
        <skos:Concept rdf:about="{concat($cpvNamespace, 'concept/', $code)}">
            <skos:notation><xsl:value-of select="$code"/></skos:notation>
            <skos:inScheme rdf:resource="{$schemeNs}"/>
            <!-- Ignore non-existing broader for supplementary codes -->
            <xsl:if test="local-name(.) = 'CPV'">
                <xsl:call-template name="getBroader">
                    <xsl:with-param name="code" select="$code"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates/>
        </skos:Concept>
    </xsl:template>
    
    <xsl:template name="getBroader">
        <xsl:param name="code"/>
        <xsl:variable name="meaningfulDigits">
            <xsl:call-template name="rstripZero">
                <xsl:with-param name="text" select="$code"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="meaningfulDigitsLength" select="string-length($meaningfulDigits)"/>
        <xsl:choose>
            <xsl:when test="$meaningfulDigitsLength &gt; 2">
                <xsl:call-template name="padBroader">
                    <xsl:with-param name="meaningfulDigitsBroader" select="substring($meaningfulDigits, 0, $meaningfulDigitsLength)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
               <skos:topConceptOf rdf:resource="{$cpvScheme}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="padBroader"> 
        <!-- Adapted from:
          https://weso.googlecode.com/hg/trunk/projects/10ders/pscs/cpv/2008/generate-cpv.py
        -->
        <xsl:param name="meaningfulDigitsBroader"/>
        <xsl:choose>
            <xsl:when test="string-length($meaningfulDigitsBroader) &lt; 8">
                <xsl:call-template name="padBroader">
                    <xsl:with-param name="meaningfulDigitsBroader" select="concat($meaningfulDigitsBroader, '0')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <skos:broaderTransitive rdf:resource="{concat($cpvNamespace, 'concept/', $meaningfulDigitsBroader)}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="rstripZero">
        <xsl:param name="text"/>
        <xsl:variable name="textLength" select="string-length($text)"/>
        <xsl:choose>
            <xsl:when test="substring($text, $textLength) = '0'">
                <xsl:call-template name="rstripZero">
                    <xsl:with-param name="text" select="replace($text, '0$', '')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="TEXT">
        <skos:prefLabel xml:lang="{lower-case(@LANG)}">
            <xsl:apply-templates/>
        </skos:prefLabel>
    </xsl:template>
    
</xsl:stylesheet>

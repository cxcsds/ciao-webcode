<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--* 
    * Templates that are used by both the ahelp and generic code.
    * The ahelp code should be re-written so that they use the
    * same set up as everything else, but doing this incrementally,
    * and very slowly.
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:func="http://exslt.org/functions"
  xmlns:djb="http://hea-www.harvard.edu/~dburke/xsl/"
  xmlns:extfuncs="http://hea-www.harvard.edu/~dburke/xsl/extfuncs"
  extension-element-prefixes="date func djb extfuncs">

  <!--* Change this if the filename changes *-->
  <xsl:variable name="hack-import-common" select="extfuncs:register-import-dependency('common.xsl')"/>

  <!--*
      * SAO/SI mandated header items.
      *
      * Also add in the favicon here to make things simpler,
      * if not cleaner/semantically sensible.
      *
      * Uses:
      *    $favicon
      *    $lastmodiso
      *    $site
      *    $desc
      *    info/metalist
      *-->
  <xsl:template name="add-sao-metadata">
    <xsl:param name="title"/>
    <xsl:if test="not(boolean($title))">
      <xsl:message terminate="yes">
 Internal Error: add-sao-metadata called but title parameter not set.
      </xsl:message>
    </xsl:if>

    <xsl:if test="$favicon != ''">
      <link rel="icon" href="{$favicon}"/>
    </xsl:if>

    <meta name="title"><xsl:attribute name="content"><xsl:value-of select="$title"/></xsl:attribute></meta>
    <meta name="creator" content="SAO-HEA"/>
    <meta http-equiv="content-language" content="en-US"/>
    <xsl:if test="$lastmodiso != ''">
      <meta name="date" content="{$lastmodiso}"/>
    </xsl:if>
      
    <!--*
	* TODO: could add in tags/logic to set these to something more specific
	*
	* -->
    <xsl:variable name="desc"><xsl:choose>
	<xsl:when test="$site = 'ciao'">The CIAO software package for analyzing data from X-ray telescopes, including the Chandra X-ray telescope.</xsl:when>
	<xsl:when test="$site = 'sherpa'">The Sherpa package for fitting and modeling data (part of CIAO).</xsl:when>
	<xsl:when test="$site = 'chips'">The ChIPS package for plotting and imaging data (part of CIAO).</xsl:when>
	<xsl:when test="$site = 'csc'">The Chandra Source Catalog</xsl:when>
	<xsl:when test="$site = 'pog'">Help for writing proposals for the Chandra X-ray telescope.</xsl:when>
	
	<xsl:when test="$site = 'iris'">IRIS - the VAO Spectral Energy Distribution Analysis Tool</xsl:when>
	
	<xsl:otherwise>Information about the Chandra X-ray Telescope for Astronomers.</xsl:otherwise>
    </xsl:choose></xsl:variable>

    <!--* Fall backs, for the common case where pages do not have specific information *-->
    <xsl:if test="not(boolean(info/metalist/meta[@name='subject']))">
      <meta name="subject" content="{$desc}"/>
    </xsl:if>
    <xsl:if test="not(boolean(info/metalist/meta[@name='description']))">
      <meta name="description" content="{$desc}"/>
    </xsl:if>
    
    <meta name="keywords" content="SI,Smithsonian,Smithsonian Institute"/>
    <meta name="keywords" content="CfA,SAO,Harvard-Smithsonian,Center for Astrophysics"/>
    <meta name="keywords" content="HEA,HEAD,High Energy Astrophysics Division"/>

  </xsl:template> <!-- name=add-sao-metadata -->

</xsl:stylesheet>

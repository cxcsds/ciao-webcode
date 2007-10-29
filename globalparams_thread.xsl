<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * List of "global" templates for the thread stylesheets
    *
    * Note:
    *  load in the default global parameters and then add thread-related
    *  ones
    *
    * Parameters:
    *  . threadDir=location of input thread XML files
    *    [the published versions, not the working copies]
    *    defaults to /data/da/Docs/<site>web/published/<type>/threads/
    *
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* NOTE we default to a depth of 3 (unlike most cases) *-->
  <xsl:param name="depth" select="3"/>

  <!--* where are the include files stored ? *-->
  <xsl:variable name="includeDir" select='concat($sourcedir,"../include/")'/>

  <!--* parameters/variables whose values are taken from the input XML file *-->
  <xsl:variable name="threadInfo"    select="/thread/info"/>
  <xsl:variable name="threadName"    select="$threadInfo/name"/>

<!--* has been superceeded by siteversion parameter
  <xsl:variable name="threadVersion" select="$threadInfo/version"/>
    *-->

  <xsl:variable name="lastentry"
    select="$threadInfo/history/entry[position()=count($threadInfo/history/entry)]"/>
  <xsl:variable name="year"><xsl:choose>
      <xsl:when test="$lastentry/@year > 1999"><xsl:value-of select="$lastentry/@year"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="2000+$lastentry/@year"/></xsl:otherwise>
    </xsl:choose></xsl:variable>
  <xsl:variable name="lastmodified"
    select="concat($lastentry/@day,' ',$lastentry/@month,' ',$year)"/>

  <!--* important that this is a parameter, not a variable *-->
  <xsl:param name="lastmod" select="$lastmodified"/>

  <!--*
      * now load in the set of "global" parameters
      * - we do this last so that we can over-ride settings above
      *-->
  <xsl:include href="globalparams.xsl"/>

  <!--* 
      * location of threads: do we need this ?
      * 
      * notes:
      * - it depends on both the site and type of the transform
      * - we look in the 'published' directory rather than the
      *   working directory when querying the threads
      * - can be over-ridden by the XSLT processor (useful for testing)
      * 
      *-->
  <xsl:param name="threadDir" select="concat('/data/da/Docs/',$site,'web/published/',$type,'/threads/')"/>

</xsl:stylesheet>

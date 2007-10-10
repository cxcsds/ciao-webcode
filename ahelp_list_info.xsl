<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * $Id: ahelp_list_info.xsl,v 1.4 2003/05/13 14:50:59 dburke Exp $ 
    *
    * List useful information from an XML file whose root node is
    * cxchelptopcis and whose ENTRY/@key != "onapplication"
    *

In the following E/@foo meens ENTRY/@foo

E/@key E/@context E/ADDRESS/URL E/ADDRESS/URL [seealsogroup1 ... seealsogroupN] SYNOPSIS

    *   
    * Recent changes:
    *   v1.4 - no longer die if there are no ADDRESS blocks
    *   v1.3 - seealso group surrounded by [] and followed by syntax
    *          section (all on one line)
    *   v1.2 - output seealso groups as well, and always 2 URL values
    *          (if don't exist use the string NULL)
    *   v1.1 - initial version
    *
    *-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  <xsl:template match="//cxchelptopics/ENTRY[@key != 'onapplication']">

    <!--* key/context *-->
    <xsl:value-of select="normalize-space(@key)"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="normalize-space(@context)"/>
    <xsl:text> </xsl:text>

    <!--* URLs *-->
    <xsl:variable name="nURL" select="count(ADDRESS/URL)"/>
    <xsl:choose>
      <xsl:when test="$nURL = 1">
	<xsl:value-of select="normalize-space(ADDRESS[1]/URL)"/>
	<xsl:text> NULL </xsl:text>
      </xsl:when>
      <xsl:when test="$nURL = 2">
	<xsl:value-of select="normalize-space(ADDRESS[1]/URL)"/>
	<xsl:text> </xsl:text>
	<xsl:value-of select="normalize-space(ADDRESS[2]/URL)"/>
	<xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>NULL NULL </xsl:text>
<!--*
	<xsl:message terminate="yes">
Number of ADDRESS/URL elements = <xsl:value-of select="$nURL"/> 
	</xsl:message>
    *-->
      </xsl:otherwise>
    </xsl:choose>

    <!--* see also groups *-->
    <xsl:text>[</xsl:text>
    <xsl:value-of select="normalize-space(@seealsogroups)"/>
    <xsl:text>] </xsl:text>

    <!--* synopsis *-->
    <xsl:value-of select="normalize-space(SYNOPSIS)"/>

    <!--* finish off with a new line *-->
    <xsl:text>
</xsl:text>
  </xsl:template>
  <xsl:template match="text()|@*|processing-instruction()|comment()"/>
</xsl:stylesheet>

<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * Strip out only those elements that contain a proglang attribute
    * and whose value (of the attribute) does not equal the
    * proglang parameter.
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml"/>

  <xsl:param name="proglang" select='""'/>

  <xsl:template match="/">
    <xsl:if test="$proglang = ''">
      <xsl:message terminate="yes">
  ERROR: proglang parameter not set
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * I want to say
      *   <xsl:template match="*[boolean(@proglang) and @proglang!=$proglang]"/>
      * but this doesn't work with xsltproc version
      *   Using libxml 20629, libxslt 10121 and libexslt 813
      *   xsltproc was compiled against libxml 20628, libxslt 10121 and libexslt 813
      *   libxslt 10121 was compiled against libxml 20628
      *   libexslt 813 was compiled against libxml 20628
      * so we have to be a lot uglier
      *-->

  <xsl:template match="@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*">
    <xsl:if test='(boolean(@proglang) and @proglang=$proglang) or boolean(@proglang)=false()'>
      <xsl:copy>
	<xsl:apply-templates select="*|@*|text()"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

<!--
  <xsl:template match="*[boolean(@proglang) and @proglang!=$proglang]"/>
  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>
-->
  
</xsl:stylesheet>
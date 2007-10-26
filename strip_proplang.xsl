<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * Strip out only those elements that contain a proplang attribute
    * and whose value (of the attribute) does not equal the
    * proplang parameter.
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml"/>

  <xsl:param name="proplang" select='""'/>

  <xsl:template match="/">
    <xsl:if test="$proplang = ''">
      <xsl:message terminate="yes">
  ERROR: proplang parameter not set
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <!--*
      * I want to say
      *   <xsl:template match="*[boolean(@proplang) and @proplang!=$proplang]"/>
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
    <xsl:if test='(boolean(@proplang) and @proplang=$proplang) or boolean(@proplang)=false()'>
      <xsl:copy>
	<xsl:apply-templates select="*|@*|text()"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

<!--
  <xsl:template match="*[boolean(@proplang) and @proplang!=$proplang]"/>
  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>
-->
  
</xsl:stylesheet>

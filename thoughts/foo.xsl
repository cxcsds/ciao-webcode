<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//links"/>
  </xsl:template>

  <xsl:template match="links">
    <xsl:call-template name="check-empty"/>
    <xsl:call-template name="links2">
      <xsl:with-param name="contents"><xsl:apply-templates/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="check-empty">
    <xsl:message> links-&gt; flag={<xsl:value-of select="count(child::*)=0 and normalize-space(.) = ''"/>}</xsl:message>
  </xsl:template>

  <xsl:template name="links2">
    <xsl:param name="contents" select="''"/>
    <xsl:message>
 contents=[<xsl:value-of select="normalize-space($contents)"/>] [<xsl:value-of select="count($contents)"/>] [<xsl:value-of select="name($contents)"/>]
    </xsl:message>
  </xsl:template>

<!--
  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
-->

</xsl:stylesheet>

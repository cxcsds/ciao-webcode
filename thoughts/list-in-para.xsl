<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>

  <xsl:param name="fname" select="'undef'"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//list"/>
  </xsl:template>

  <xsl:template match="list">
    <xsl:if test="boolean(ancestor::p)">
      <xsl:text>Found a list within a p for </xsl:text>
      <xsl:value-of select="$fname"/><xsl:text>
</xsl:text>
    </xsl:if>
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

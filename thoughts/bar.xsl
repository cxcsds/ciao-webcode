<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//bar" mode="a"/>
  </xsl:template>

  <xsl:template match="bar" mode="a">
    START: <xsl:apply-templates select="start"/>
    <xsl:apply-templates select="*[name() != 'start']" mode="a"/>
  </xsl:template>

  <xsl:template match="a" mode="a">
    <xsl:text>a: </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="b" mode="a">
    <xsl:text>b: </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="c" mode="a">
    <xsl:text>c: </xsl:text>
    <xsl:apply-templates/>
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

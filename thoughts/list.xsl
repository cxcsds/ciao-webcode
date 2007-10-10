<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE xsl:stylesheet>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>
  <xsl:template match="/">

    <xsl:apply-templates select="//list"/>
  </xsl:template>

  <xsl:template match="list">
    <xsl:text>List title: </xsl:text><xsl:apply-templates select="title"/><xsl:text>
</xsl:text>

    <xsl:apply-templates select="*[name() != 'title']"/>
  </xsl:template>

  <xsl:template match="sublist">
    <xsl:text>-----start-sub-list
Sub-List title: </xsl:text><xsl:apply-templates select="title"/><xsl:text>
</xsl:text>

    <xsl:apply-templates select="*[name() != 'title']"/>
    <xsl:if test="name(following-sibling::*[1]) = 'item'">
      <xsl:text>-----end-sub-list
</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="item">
    <xsl:text>item: </xsl:text><xsl:value-of select="."/><xsl:text>
</xsl:text>
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

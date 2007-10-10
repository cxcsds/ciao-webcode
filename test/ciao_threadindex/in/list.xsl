<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:include href="../../../globalparams_thread.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <xsl:include href="../../../threadindex_common.xsl"/>
  <xsl:output method="html" media-type="text/html" version="4.0" encoding="us-ascii"/>
<xsl:template match="/">
 <xsl:apply-templates select="//list" mode="threadindex">
  <xsl:with-param name="depth" select="$depth"/>
 </xsl:apply-templates>
</xsl:template>
<xsl:template name="newline"><xsl:text>
</xsl:text></xsl:template>
</xsl:stylesheet>

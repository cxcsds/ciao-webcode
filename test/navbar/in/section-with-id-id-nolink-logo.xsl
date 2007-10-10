<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:param name="logoimage" select='"logo.gif"'/>
  <xsl:param name="logotext"  select='"LOGO TEXT"'/>
  <xsl:param name="sourcedir"  select='"foo"'/>
  <xsl:include href="../../../globalparams.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <xsl:include href="../../../navbar_main.xsl"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//section" mode="with-id">
    <!-- dir param only used by mode=process and we can live with default there -->
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>
</xsl:stylesheet>

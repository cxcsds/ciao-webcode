<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href="../../../globalparams.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <xsl:include href="../../../navbar_main.xsl"/>
<xsl:param name="logotext" select='"Logo Text"'/>
<xsl:param name="logoimage" select='"logo.gif"'/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:for-each select="descendant::section[boolean(@id)]/dirs/dir[.!='']">
    <xsl:call-template name="navbar-contents"/>
  </xsl:for-each>
</xsl:template>
</xsl:stylesheet>

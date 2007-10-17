<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href='../../../globalparams.xsl'/>
  <xsl:include href='../../../helper.xsl'/>
  <xsl:include href='../../../myhtml.xsl'/>
  <xsl:include href='../../../links.xsl'/>

<xsl:template match='test'>
<xsl:text>
</xsl:text>
<xsl:call-template name="add-id-hardcopy">
  <xsl:with-param name="urlfrag" select="'foo/foo.html'"/>
  <xsl:with-param name="lastmod" select="'29 Jan 1971'"/>
</xsl:call-template>

  </xsl:template>
<!--* need to sort out newline template! *-->
<xsl:template name='newline'><xsl:text>
</xsl:text></xsl:template>
</xsl:stylesheet>
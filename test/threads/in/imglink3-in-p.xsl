<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:include href="../../../globalparams.xsl"/>
  <xsl:include href="../../../thread_common.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <!--* has to be after thread_commmon since that sets output to text *-->
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//p"/>
</xsl:template>
</xsl:stylesheet>

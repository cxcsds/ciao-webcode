<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href="../../../ahelp_main.xsl"/>
  <xsl:strip-space elements="SYNTAX PARA"/> <!--* addded for CIAO 3.1 *-->
<xsl:template match="/"><xsl:apply-templates select="cxchelptopics/ENTRY" mode="test"/></xsl:template>
<xsl:template match="ENTRY" mode="test">
<xsl:text>
</xsl:text>
  <xsl:call-template name="create-syntax-from-paramlist"/>
  <xsl:text>@@</xsl:text>
</xsl:template>
</xsl:stylesheet>

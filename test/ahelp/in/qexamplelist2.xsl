<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href="../../../ahelp_main.xsl"/>
  <xsl:strip-space elements="SYNTAX PARA"/> <!--* addded for CIAO 3.1 *-->
<xsl:variable name="maxlen" select="10"/>
<xsl:variable name="nexample" select="count(//ENTRY/QEXAMPLELIST/QEXAMPLE)"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//QEXAMPLELIST"/>
</xsl:template>
</xsl:stylesheet>

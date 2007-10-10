<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href="../../../ahelp_main.xsl"/>
  <xsl:strip-space elements="SYNTAX PARA"/> <!--* addded for CIAO 3.1 *-->
<xsl:param name="seealso" select="document($seealsofile)/seealso"/>
<xsl:param name="have-seealso"  select="$seealso != ''"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:call-template name="add-seealso"/>
</xsl:template>
</xsl:stylesheet>

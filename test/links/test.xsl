<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href='../../globalparams.xsl'/>
  <xsl:include href='../../myhtml.xsl'/>
  <xsl:include href='../../helper.xsl'/>
  <xsl:include href='../../links.xsl'/>
  <xsl:template match='thread|test'>
    <xsl:apply-templates>
      <xsl:with-param name='depth' select='$depth'/>
    </xsl:apply-templates>
  </xsl:template>
</xsl:stylesheet>

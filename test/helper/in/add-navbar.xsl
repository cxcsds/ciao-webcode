<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href='../../../globalparams.xsl'/>
  <xsl:include href='../../../helper.xsl'/>
  <xsl:include href='../../../myhtml.xsl'/>
  <xsl:include href='../../../links.xsl'/>
  <xsl:param name="xsl-version" select="'1.2.3'"/>
  <xsl:param name="updateby"    select="'a_tester'"/>
<xsl:template match='test'>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-navbar">
      <xsl:with-param name="name"       select="'test'"/>
      <xsl:with-param name="depth"      select="$depth"/>
      <xsl:with-param name="type"       select="$type"/>
    </xsl:call-template>
  </xsl:template>
<!--* need to sort out newline template! *-->
<xsl:template name='newline'><xsl:text>
</xsl:text></xsl:template>
</xsl:stylesheet>
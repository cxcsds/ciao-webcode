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
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"   select="'foo.gif'"/>
      <xsl:with-param name="alt"   select="'a foo'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="'foo.gif'"/>
      <xsl:with-param name="alt"    select="'a foo'"/>
      <xsl:with-param name="height" select="'10'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="'foo.gif'"/>
      <xsl:with-param name="alt"    select="'a foo'"/>
      <xsl:with-param name="width"  select="'20'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="'foo.gif'"/>
      <xsl:with-param name="alt"    select="'a foo'"/>
      <xsl:with-param name="border" select="0"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="'foo.gif'"/>
      <xsl:with-param name="alt"    select="'a foo'"/>
      <xsl:with-param name="align"  select="'right'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="'foo.gif'"/>
      <xsl:with-param name="alt"    select="'a foo'"/>
      <xsl:with-param name="border" select="0"/>
      <xsl:with-param name="align"  select="'right'"/>
      <xsl:with-param name="width"  select="'20'"/>
      <xsl:with-param name="height" select="'10'"/>
    </xsl:call-template>

  </xsl:template>
<!--* need to sort out newline template! *-->
<xsl:template name='newline'><xsl:text>
</xsl:text></xsl:template>
</xsl:stylesheet>

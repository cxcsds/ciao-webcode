<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href="../../../ahelp_main.xsl"/>
  <xsl:strip-space elements="SYNTAX PARA"/> <!--* addded for CIAO 3.1 *-->
<xsl:variable name="nparam"     select="count(//ENTRY/PARAMLIST/PARAM)"/>
<xsl:variable name="have-ftype" select="count(//PARAM[@filetype])!=0"/>
<xsl:variable name="have-def"   select="count(//PARAM[@def])!=0"/>
<xsl:variable name="have-min"   select="count(//PARAM[@min])!=0"/>
<xsl:variable name="have-max"   select="count(//PARAM[@max])!=0"/>
<xsl:variable name="have-units" select="count(//PARAM[@units])!=0"/>
<xsl:variable name="have-reqd"  select="count(//PARAM[@reqd])!=0"/>
<xsl:variable name="have-stcks" select="count(//PARAM[@stacks])!=0"/>
<xsl:variable name="have-aname" select="count(//PARAM[@autoname])!=0"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARAMLIST"/>
</xsl:template>
</xsl:stylesheet>

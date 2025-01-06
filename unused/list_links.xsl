<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE xsl:stylesheet>

<!--*
    * list local href links that end in '/'
    * intended for 'xsptproc -html ....'
    *-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--* output is plain text *-->
  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:for-each select="//a[
(substring(@href, string-length(@href)) = '/')
and
(substring(@href, 1, 4) != 'http')
]">
<xsl:value-of select="@href"/><xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
